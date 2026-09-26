# marswrapper.har 更新说明

本目录下的`marswrapper.har`是野火IM原生 SDK（内含`libmarswrapper.so`、`libc++_shared.so`及 ArkTS 层），由`client/oh-package.json5`以本地文件方式依赖：

```
"@wfc/marswrapper": "file:./libs/marswrapper.har"
```

## 重要提醒：替换文件后必须重装依赖

该依赖是`file:`本地依赖，且 har 内版本号固定为`1.0.0`。ohpm 安装时会把它解到内容缓存`oh_modules/.ohpm/`中，各模块`oh_modules/@wfc/marswrapper`只是指向缓存的软链。**只替换本目录下的 har 文件，ohpm 不会感知变化，编译出来的应用仍是旧库。**

## 更新步骤

1. 用新版`marswrapper.har`覆盖本目录下的同名文件。
2. 在项目根目录执行：

   ```bash
   rm -rf oh_modules/.ohpm client/oh_modules chat/oh_modules entry/oh_modules uikit/oh_modules moment/oh_modules
   ohpm install
   ```

   使用 DevEco Studio 时对应操作：删除上述目录后，执行 File -> Sync and Refresh Project。
3. 验证更新是否生效，确认以下文件的日期/大小已变为新版：

   ```bash
   ls -la client/oh_modules/@wfc/marswrapper/libs/arm64-v8a/
   ```

4. 重新编译运行。

## 备注

- 若 har 内版本号有递增（如`1.0.1`），ohpm 锁文件会随之变化，可正常触发重新安装，无需手动清缓存。
