#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

// 匹配路径中的文件名
void match(const char* path, const char* name) {
    int pathIndex = 0;
    int nameIndex = 0;

    // 遍历路径字符串
    while (path[pathIndex] != 0) {
        nameIndex = 0;
        int tempIndex = pathIndex;

        // 检查子字符串是否与name匹配
        while (name[nameIndex] != 0) {
            if (name[nameIndex] == path[tempIndex]) {
                nameIndex++;
                tempIndex++;
            } else {
                break;
            }
        }

        // 如果完整匹配name，则打印路径
        if (name[nameIndex] == 0) {
            printf("%s\n", path);
            return;
        }
        pathIndex++;
    }
}

// 递归查找路径中的文件
void find(const char *path, const char *name) {
    char buffer[512], *ptr;
    int fileDescriptor;
    struct dirent directoryEntry;
    struct stat status;

    // 打开目录
    if ((fileDescriptor = open(path, 0)) < 0) {
        fprintf(2, "无法打开 %s\n", path);
        return;
    }

    // 获取目录信息
    if (fstat(fileDescriptor, &status) < 0) {
        fprintf(2, "无法获取状态 %s\n", path);
        close(fileDescriptor);
        return;
    }

    // 根据文件类型处理
    switch (status.type) {
        case T_FILE:
            // 如果是文件，尝试匹配
            match(path, name);
            break;

        case T_DIR:
            // 如果是目录，递归查找
            if (strlen(path) + 1 + DIRSIZ + 1 > sizeof(buffer)) {
                printf("路径过长\n");
                break;
            }

            strcpy(buffer, path);
            ptr = buffer + strlen(buffer);
            *ptr++ = '/';

            // 读取目录内容
            while (read(fileDescriptor, &directoryEntry, sizeof(directoryEntry)) == sizeof(directoryEntry)) {
                if (directoryEntry.inum == 0)
                    continue;

                // 跳过 "." 和 ".."
                if (directoryEntry.name[0] == '.' && directoryEntry.name[1] == 0) continue;
                if (directoryEntry.name[0] == '.' && directoryEntry.name[1] == '.' && directoryEntry.name[2] == 0) continue;

                memmove(ptr, directoryEntry.name, DIRSIZ);
                ptr[DIRSIZ] = 0;

                // 获取目录项状态
                if (stat(buffer, &status) < 0) {
                    printf("无法获取状态 %s\n", buffer);
                    continue;
                }

                // 递归查找
                find(buffer, name);
            }
            break;
    }

    close(fileDescriptor); // 关闭目录
}

int main(int argc, char *argv[]) {
    // 检查参数数量
    if (argc < 3) {
        printf("用法: find [路径] [文件名]\n");
        exit(1);
    }

    // 调用查找函数
    find(argv[1], argv[2]);
    exit(0); // 正常退出程序
}
