#
# main() will be invoked when you Run This Action
#
# @param Cloud Functions actions accept a single parameter, which must be a JSON object.
#
# @return The output of this action, which must be a JSON object.
#
#
import sys
import requests
import json

DEBUG = False

successhtml = '''
<HTML>
  <HEAD>
    <TITLE>Release Build</TITLE>
  </HEAD>
  <BODY BGCOLOR="FFFFFF">
    <CENTER><IMG SRC="http://www.kitura.io/favicon.ico" ALIGN="BOTTOM"> </CENTER>
    <HR>
    <H1>Release build request submitted</H1>
  </BODY>
</HTML>
'''

errorhtml = '''
<HTML>
  <HEAD>
    <TITLE>%(code)d</TITLE>
  </HEAD>
  <BODY BGCOLOR="FFFFFF">
    <CENTER><IMG SRC="http://www.kitura.io/favicon.ico" ALIGN="BOTTOM"> </CENTER>
    <HR>
    <H1>Error %(code)d, %(text)s</H1>
  </BODY>
</HTML>
'''

def query_convert(query):
    '''
    convert the query arguments into a dictionary.
    '''
    query_list = query.replace('?','').split('&')
    query_params = {}

    for param in query_list:
        k, v = param.split('=')
        query_params[k] = v
    return query_params

def success_response(code):
    response = {'html': successhtml,
                'statusCode': code }
    return response

def error_response(code, text):
    response = {'html': errorhtml % {'code': code,
                                     'text': text},
                'statusCode': code }
    return response

def travis_login(github_token):
    '''
    Use a github_token to login to travis.
    '''
    travis_login_api = 'https://api.travis-ci.org/auth/github'
    payload = {'github_token': github_token}
    headers = {'Accept': 'application/vnd.travis-ci.2+json',
                'Content-Type': 'application/json',
                'User-Agent': 'MyClient/1.0.0'}

    response = requests.post(travis_login_api, headers=headers, data=json.dumps(payload))
    response.raise_for_status()
    result = response.json()

    if DEBUG:
        print('*** ACCESS TOKEN ***')
        for k in result.keys():
            print('%s => %s' % (k, result[k]))

    # now it is possible to interract with travis using the returned travis token:
    return response['access_token']

def travis_request_build(travis_access_token, org, repo):
    '''
    Request a travis build on the selected org and repo
    '''
    travis_request_api = 'https://api.travis-ci.org/repo/%(org)s%%2F%(repo)s/requests' % {'org': org,
                                                                                          'repo': repo}
    payload = { 'request': {'branch': 'master'}}
    headers = { 'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Travis-API-Version': '3',
                'Authorization': 'token %(tac)s' % {'tac': travis_access_token}}
    response = requests.post(travis_request_api, headers=headers, data=json.dumps(payload))
    response.raise_for_status()

    result = response.json()
    if DEBUG:
        print('*** TRAVIS REQUEST BUILD RESPONSE ***')
        for k in result.keys():
            print('%s => %s' % (k, result[k]))

    # return the response from the request
    return result()

def github_access_token(client_id, client_secret, code, state):
    github_access_token_api = 'https://github.com/login/oauth/access_token?' \
                              'client_id=%(client_id)s&' \
                              'client_secret=%(client_secret)s&' \
                              'code=%(code)s&' \
                              'state=%(state)s&' % {'client_id': client_id,
                                                    'client_secret': client_secret,
                                                    'code': code,
                                                    'state': state}
    headers = {'Accept': 'application/json',
               'Content-Type': 'application/json',
               'User-Agent': 'MyClient/1.0.0'}
    response = requests.post(github_access_token_api, headers=headers)
    response.raise_for_status()
    access = response.json()

    return access

def github_user_credentials(access_token):
    github_user_credentials_api = 'https://api.github.com/user?' \
                                  'access_token=%(access_token)s' % {'access_token': access_token}

    headers = {'Accept': 'application/vnd.github+json',
               'Content-Type': 'application/json',
               'User-Agent': 'MyClient/1.0.0'}
    response = requests.get(github_user_credentials_api, headers=headers)
    response.raise_for_status()
    credentials = response.json()

    if DEBUG:
        print('*** USER CREDENTIALS ***')
        for k in credentials.keys():
            print('%s => %s' % (k, credentials[k]))

    return credentials

def main(args):
    # for convenience and tidiness, pull all the data needed into local variables.
    client_id = args['client_id']
    client_secret = args['client_secret']
    github_token = args['github_token']
    org = args['org']
    repo = args['repo']
    DEBUG = args.get('debug', 'false') == 'true'

    if DEBUG:
        print('process query arguments', args['__ow_query'])
    if not '__ow_query' in args:
        if DEBUG:
            print('Error: missing query arguments')

    # turn the query parameters into a dictionary
    query_params = query_convert(args['__ow_query'])

    if DEBUG:
        print('*** ARGS ***')
        for k in args.keys():
            if k in ['client_secret', 'github_token', 'authorized_users']:
                print('%s => %s' % (k, '************************'))
                continue
            print('%s => %s' % (k, args[k]))

        print('*** QUERY PARAMETERS ***')
        for k in query_params.keys():
            print('%s => %s' % (k, query_params[k]))

    code = query_params['code']
    state = query_params['state']

    # check for correct state value
    if state != 'ea715df50b4df79314711fe484469a1f':
        return error_response(401, 'Unauthorized')

    # turn the authorized users into a list
    authorized_users = [user.strip() for user in args['authorized_users'].split(',')]

    # get the access token from github
    access = github_access_token(client_id=client_id,
                                 client_secret=client_secret,
                                 code=code,
                                 state=state)
    access_token = access['access_token']

    # get the logged in user credentials
    credentials = github_user_credentials(access_token)
    login = credentials['login']

    # if the user is in our list, got ahead and do the release build
    if not login in authorized_users:
        return error_response(401, 'Not Authorized')

    if DEBUG: print('user %s is authorized' % login)

    try:
        # now login to travis
        travis_access_token = travis_login(github_token)
    except Exception as e:
        return error_response(e.response.status_code, e.response.reason)

    # next, talk to travis to request a new build on master
    try:
        # now request the build
        result = travis_request_build(travis_access_token, org=org, repo=repo)
        if result['@type'] != 'pending':
            # something went wrong
            return error_response(500, 'Internal Server Error')
    except Exception as e:
        return error_response(e.response.status_code, e.response.reason)

    # successfully submitted
    return success_response(200)
