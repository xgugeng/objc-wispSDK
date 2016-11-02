# WISP SDK介绍

本SDK用于获取用户HTTP/HTTPS请求的性能统计。

## 原理：

使用NSURLProtocol去重新定义苹果的[URL加载系统](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html#//apple_ref/doc/uid/10000165-BCICJDHA) (URL Loading System)的行为。当URL Loading System使用NSURLRequest去获取资源的时候，它会创建一个NSURLProtocol子类的实例。我们重新实现了NSURLProtocol的方法以获得请求相关的详细信息：

- 请求URL
- 首包时间
- 总下载字节
- 总下载时间
- 错误码
- 错误描述

目前支持NSURLConnection、NSURLSession、AFNetworking、第三方库。

## 使用：

这里有一个[简单的例子](https://github.com/hellokangning/wispSample)。

### 1. Podfile

```ruby
platform :ios, '7.0'
pod 'QiniuWISP', '~> 0.1.4'
```

### 2. 手动
将[objc-wispSDK](https://github.com/hellokangning/objc-wispSDK/tree/master/objc-wispSDK)目录下的源文件（.h和.m）拷贝到自己的项目中。

使用例子：

```objective-c
[WISPURLProtocol enableWithAppID:@"57f89e2e61f0c4745ffe6bbf"
                           andAppKey:@"57f89e2e4cf0836f0a60a161"];
```

