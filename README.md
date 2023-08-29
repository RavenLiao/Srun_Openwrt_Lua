# 深澜认证协议OpenWrt-Lua版

依据别人的python代码改写的lua版本。使用的是5.3版本，而不是默认的5.1，主要是因为5.1不支持64位整数和位运算，计算时有问题。

## 适用范围

目前测试成功的Srun版本：

>V1.18 B20190222

适用的学校:

> 哈工深

欢迎大伙提供成功案例，[补充在issue中](https://github.com/Raven-L/Srun_Openwrt_Lua/issues/1)。

当然如果发现不成功，也欢迎提出issue。

## 使用

### 依赖

1. openSSL：`opkg install openssl-util`

2. lua5.3：`opkg install lua5.3`

3. curl 一般自带

### 配置

   `login.lua`已经是完整的登录脚本，填入

```lua
username = ""
password = ""
```

执行脚本就好：`lua5.3 login.lua`

## 感谢

服务相关参考：https://github.com/CHxCOOH/Srun_Openwrt/tree/main

原始的Python代码：https://github.com/huxiaofan1223/jxnu_srun