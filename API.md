## 目前睿思支持的API
> 注意只有校园网支持rsbbs.xidian.edu.cn不支持
> 如果有遗漏的欢迎补充

1. [登录][1]
```
{
    "Version": "3",
    "Charset": "UTF-8",
    "Variables": {
        "cookiepre": "Q8qA_2132_",
        "auth": null,
        "saltkey": "He3Tw30s",
        "member_uid": "0",
        "member_username": "",
        "groupid": "7",
        "formhash": "ab3d001b",
        "ismoderator": null,
        "readaccess": "1",
        "notice": {
            "newpush": "0",
            "newpm": "0",
            "newprompt": "0",
            "newmypost": "0"
        }
    }
}

{
    "Version": "3",
    "Charset": "UTF-8",
    "Variables": {
        "cookiepre": "Q8qA_2132_",
        "auth": "8824ZhhuzwXH6vpzvR3HoVvvElFKALjMD1k8k/6PR+EHdi40M1cdlcKStFAnKzFAR574jr+V/QXxhhJ2rQOzLP3vtRQ",
        "saltkey": "He3Tw30s",
        "member_uid": "252553",
        "member_username": "谁用了FREEDOM",
        "groupid": "25",
        "formhash": "cc2c52bf",
        "ismoderator": null,
        "readaccess": "70",
        "notice": {
            "newpush": "0",
            "newpm": "0",
            "newprompt": "0",
            "newmypost": "0"
        }
    },
    "Message": {
        "messageval": "login_succeed",
        "messagestr": "欢迎您回来，西电研二 谁用了FREEDOM，现在将转入登录前页面"
    }
}
````
2. [板块列表][2]
3. [帖子列表][3]
4. [帖子详情][4]
    - `ppp` 每页条数int
    - `authorid=1` 只看楼主
    - `ordertype=1` 倒序查看
    
5. [好友列表][5]
```
{
    "Version": "1",
    "Charset": "UTF-8",
    "Variables": {
        "cookiepre": "Q8qA_2132_",
        "auth": "8824ZhhuzwXH6vpzvR3HoVvvElFKALjMD1k8k/6PR+EHdi40M1cdlcKStFAnKzFAR574jr+V/QXxhhJ2rQOzLP3vtRQ",
        "saltkey": "He3Tw30s",
        "member_uid": "252553",
        "member_username": "谁用了FREEDOM",
        "groupid": "25",
        "formhash": "cc2c52bf",
        "ismoderator": null,
        "readaccess": "70",
        "notice": {
            "newpush": "0",
            "newpm": "0",
            "newprompt": "0",
            "newmypost": "0"
        },
        "list": [
            {
                "uid": "51867",
                "username": "hualong95"
            },
            {
                "uid": "65193",
                "username": "卡斯摩"
            },
            {
                "uid": "70602",
                "username": "xhmrj"
            },
            {
                "uid": "82390",
                "username": "87144959"
            }
        ],
        "count": "30"
    }
}
```
6. [用户个人信息][6]
7. [检查发帖][7]
8. [收藏帖子][8]
9. [获得表情列表][9]
10. [发帖获得板块和类型列表][10]
11. [发帖上传图片][11]
12. [发帖检查验证码][12]
    - 睿思暂不支持
13. [发帖][13]
    - `formhash: d4bc78f0`
    - `mobiletype: 5`
    - `allowphoto: 0`
    - `typeid: 0` 子分类id
    - `allownoticeauthor: 1`
    - `subject` 标题
    - `message` 内容
    - `sechash: NtG418GG`  验证码
    - `seccodeverify: c993` 验证码回答
14. [我的提醒列表][14]
15. [我的私信列表][15]
16. [我和某人的私信对话列表][16]
17. [发送私信][17]
18. [登录GET][18]
> 获得formhash等
19. [发送评论检查][19]
20. [提交评论][20]
    - `formhash`
    - `mobiletype: 5`
    - `message` 评论内容
21. [我发的帖子][21]
22. [我发的评论][22]
23. [给帖子点赞][23]
24. [热帖][24]
25. [热门板块][25]
26. [我收藏的板块][26]
27. [我收藏的帖子][27]
28. [某板块置顶帖][28]
29. [上传头像][29]


[1]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=login&action=login&username=admin&password=admin
[2]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=forumindex
[3]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=forumdisplay&fid=72
[4]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=viewthread&tid=921699
[5]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=friend
[6]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=profile&uid=262789
[7]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=checkpost
[8]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=favthread
[9]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=smiley
[10]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=forumnav
[11]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=forumupload&fid=2&type=image&simple=1
[12]:  http://rs.xidian.edu.cn/api/mobile/index.php?module=secure&type=post&version=4&secversion=4
[13]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=newthread&fid=2&topicsubmit=yes
[14]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=mynotelist
[15]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=mypm&page=1
[16]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=mypm&subop=view&touid=262789
[17]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=sendpm
[18]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=login
[19]:  http://rs.xidian.edu.cn/api/mobile/index.php?siteid=null&module=sendreply&fid=2&tid=3&submodule=checkpost&version=1
[20]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=sendreply&tid=3&pid=0&replysubmit=yes
[21]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=mythread&type=thread&ac=thread
[22]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=mythread&type=reply&ac=reply
[23]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=recommend&tid=2&hash=f1ddb805
[24]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=hotthread
[25]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=hotforum
[26]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=myfavforum
[27]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=myfavthread
[28]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=toplist&fid=72
[29]:  http://rs.xidian.edu.cn/api/mobile/index.php?version=4&module=uploadavatar
