import urllib.request

local_filename, headers = urllib.request.urlretrieve('http://classutil.unsw.edu.au/COMP_S1.html')
# html = open(local_filename)

with open(local_filename) as html:
    for line in html:
        print(line, end="")
