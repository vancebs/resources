TeamViewer官网上下载的deb包已经无法在旧版本的ubuntu上安装。以下是旧版安装Ubuntu安装TeamViewer的方法

```
# 导入key
cd /tmp && wget https://raw.githubusercontent.com/vancebs/resources/master/TeamViewer/TeamViewer.asc
sudo apt-key add TeamViewer.asc

# 导入apt源
sudo sh -c 'echo "deb http://linux.teamviewer.com/deb stable main" >> /etc/apt/sources.list.d/teamviewer.list'
sudo sh -c 'echo "deb http://linux.teamviewer.com/deb preview main" >> /etc/apt/sources.list.d/teamviewer.list'

# 更新源并安装
sudo apt update
sudo apt install teamviewer
```
