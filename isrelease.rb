# Read the release marker and return its value
# reset the release marker to false
File.open('release.txt', 'r') do |release|
  while line = release.gets
    if line =~ /^#/
      next
    end
    if line =~ /\s*release\s*=\s*true/i
      exit(true)
    end
  end 
end 
exit(false)
