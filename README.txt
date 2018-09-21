啟動此container的電腦 = docker host

使用步驟:
1.安裝docker 
  curl -sSL https://get.docker.com/ | sh
2.匯入postgresql docker image
  docker load --input postgresql_9.6.tar
3.啟動 postgresql
  docker run -itd --name postgresql -v /var/lib/postgresql:var/lib/postgresql -p 5432:5432 -p 28017:28017 -p 27017:27017 postgresql:9.6
4.由其他postgresql client 連入測試此 postgresql，密碼為wjan4219
  psql -h docker host的IP -U postgres

說明:
1.請自行熟練 docker 觀念以及使用

2.dependencies 裡包含所有包成 container 所需的檔案

3.由於 container 被刪除後，database 資料就會消失，所以請在 docker host 中建立/var/lib/postgresql，步驟3的參數 -v /var/lib/postgresql:var/lib/postgresql，會把 container 裡的 /var/lib/postgresql 存到docker host 的 /var/lib/postgresql，這樣 container 被刪除後，database 資料還會存在在 docker host 的 /var/lib/postgresql

4.查看 postgresq l的 log，有兩種方法
 A: docker logs -f postgresql
 B: 在 docker host 中建立 /var/log/postgresql，在步驟3多個參數-v /var/log/postgresql:/var/log/postgresql，啟動後可以在 docker host 中的 /var/log/postgresql 看到 log

5.如有缺少或想增加 container 內的套件或檔案，請自行修改 Dockerfile，並重新 build
  docker build -t postgresql:9.6 .
  
6.如果要建立 postgresql 裡的 database 或是 table，
應該使用 postgresql 的 client 建立 database 和匯入 table，
不適合在 build images 時建立

