#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[]){
    int parentToChild[2];  // 父进程到子进程的管道
    int childToParent[2];  // 子进程到父进程的管道
    
    if(pipe(parentToChild) < 0){  // 创建父到子的管道
        printf("pipe error");
        exit(-1);  // 如果创建管道失败，退出程序
    }
    
    if(pipe(childToParent) < 0){  // 创建子到父的管道
        printf("pipe error");
        exit(-1);  // 如果创建管道失败，退出程序
    }
    
    int pid = fork();  // 创建子进程
    
    if(pid == 0){
        // 子进程
        char readBuffer[10];
        read(parentToChild[0], readBuffer, sizeof(readBuffer));  // 从父进程读取数据
        printf("%d: received ping\n", getpid());  // 打印子进程收到的数据
        write(childToParent[1], "o", 2);  // 向父进程写入数据
    }else if(pid > 0){
        // 父进程
        write(parentToChild[1], "p", 2);  // 向子进程写入数据
        char readBuffer[10];
        read(childToParent[0], readBuffer, sizeof(readBuffer));  // 从子进程读取数据
        printf("%d: received pong\n", getpid());  // 打印父进程收到的数据
    }
    
    close(parentToChild[0]);  // 关闭父到子管道的读端
    close(parentToChild[1]);  // 关闭父到子管道的写端
    close(childToParent[0]);  // 关闭子到父管道的读端
    close(childToParent[1]);  // 关闭子到父管道的写端
    
    exit(0);  // 程序退出
}
