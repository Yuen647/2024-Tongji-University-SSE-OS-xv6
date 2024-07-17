#include "kernel/types.h" 
#include "kernel/stat.h"  
#include "user/user.h"    

// 读取一行输入
char* readline() {
    char* buffer = malloc(100);
    char* p = buffer;
    
    // 从标准输入读取字符，直到遇到换行符或字符串结束符
    while (read(0, p, 1) != 0) {
        if (*p == '\n' || *p == '\0') {
            *p = '\0'; // 将换行符或字符串结束符替换为字符串结束符
            return buffer;
        }
        p++;
    }

    // 如果缓冲区非空，返回缓冲区指针，否则释放内存
    if (p != buffer) return buffer;
    free(buffer);
    return 0;
}

int main(int argc, char *argv[]) {
    // 检查参数数量
    if (argc < 2) {
        printf("用法: xargs [命令]\n");
        exit(1);
    }

    char* line;
    argv++; // 跳过程序名参数
    char* new_argv[16]; // 新的参数列表
    char** new_argv_ptr = new_argv;
    char** argv_ptr = argv;

    // 将命令行参数复制到新的参数列表
    while (*argv_ptr != 0) {
        *new_argv_ptr = *argv_ptr;
        new_argv_ptr++;
        argv_ptr++;
    }

    // 读取每行输入
    while ((line = readline()) != 0) {
        char* p = line;
        char* buffer = malloc(36);
        char* buffer_head = buffer;
        int new_argc = argc - 1;

        // 解析输入行，将空格分隔的部分作为新的参数添加到参数列表中
        while (*p != 0) {
            if (*p == ' ' && buffer != buffer_head) {
                *buffer_head = '\0';
                new_argv[new_argc] = buffer;
                buffer = malloc(36);
                buffer_head = buffer;
                new_argc++;
            } else {
                *buffer_head = *p;
                buffer_head++;
            }
            p++;
        }

        // 添加最后一个参数
        if (buffer != buffer_head) {
            new_argv[new_argc] = buffer;
            new_argc++;
        }
        new_argv[new_argc] = 0;
        free(line);

        // 创建子进程并执行命令
        int pid = fork();
        if (pid == 0) {
            exec(new_argv[0], new_argv);
        } else {
            wait(0); // 等待子进程结束
        }
    }
    exit(0); // 正常退出程序
}
