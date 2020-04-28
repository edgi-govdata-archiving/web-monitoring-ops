1. Add the urls to Internet Archive by using https://github.com/Mr0grog/wayback-spn-client. 
  - This is possible on the server but should run locally. 
  - Created a quick txt to run this. Then deleted afterwards. 
  - This process takes about 30sec per url. 
  - ran `node /ubuntu/.../index.js <filename>`
2. Import the urls into -the database by using `-processing` command line library
  - Made sure we had a virtual environment with conda. 
  - Pip install everything and dev. 
  - Run `python setup.py develop`. 
  - Create env from sample. Then source env
  - Run command - `wm import ia "filename" --tag "tag" --maintainer "EPA"
  - Need to watch out that we get a job import ID, so we know this was successful. Also, double check at api.monitoring.envirodatagov.org
3. Add urls to text file. Commit changes to repo to keep track of changed Urls. 
  - We don't use PRs unless it's a characteristic change to the repo. In this case, updating the url list files, we can just push to master without creating new branches and PRs
4. Copy to server using `scp` command. Just like `cp` but can talk to remotes using ssh
  `scp manually-managed/ia-archiver/missing-from-ia.txt <ipaddress>:/home/ubuntu/`
5. Informs IA about added urls in scanner Slack