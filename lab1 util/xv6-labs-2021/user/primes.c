#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

void primeFilter(int readDescriptor){
    int primeNumber;
    read(readDescriptor, &primeNumber, sizeof(primeNumber));  // 读取第一个素数
    printf("prime %d\n", primeNumber);
    
    int isPipeCreated = 0;
    int pipeDescriptors[2];
    int currentNumber;
    
    while(read(readDescriptor, &currentNumber, sizeof(currentNumber)) != 0){
        if(isPipeCreated == 0){
            pipe(pipeDescriptors);  // 创建新的管道
            isPipeCreated = 1;
            int pid = fork();
            if(pid == 0){
                close(pipeDescriptors[1]);  // 关闭写端
                primeFilter(pipeDescriptors[0]);  // 递归调用
                return;
            }else{
                close(pipeDescriptors[0]);  // 关闭读端
            }
        }
        if(currentNumber % primeNumber != 0){
            write(pipeDescriptors[1], &currentNumber, sizeof(currentNumber));  // 将非倍数写入管道
        }
    }
    
    close(readDescriptor);  // 关闭读端
    close(pipeDescriptors[1]);  // 关闭写端
    wait(0);  // 等待子进程结束
}

int
main(int argc, char *argv[]){
    int initialPipe[2];
    pipe(initialPipe);

    int pid = fork();
    if(pid != 0){
        // 父进程
        close(initialPipe[0]);  // 关闭读端
        for(int i = 2; i <= 35; i++){
            write(initialPipe[1], &i, sizeof(i));  // 写入数值
        }
        close(initialPipe[1]);  // 关闭写端
        wait(0);  // 等待子进程结束
    }else{
        // 子进程
        close(initialPipe[1]);  // 关闭写端
        primeFilter(initialPipe[0]);  // 调用过滤函数
        close(initialPipe[0]);  // 关闭读端
    }
    
    exit(0);  // 程序退出
}

