# Read the release marker and return its value
# reset the release marker to false
File.open('release.txt', 'r+') do |release|
  while line = release.gets
    if line =~ /^#/
      next
    end
    if line =~ /\s*release\s*=\s*true/i
      release.seek(0 - (line.length),IO::SEEK_CUR)
      release.write("release = false")
      release.truncate(release.pos) 
    end
  end 
end 
