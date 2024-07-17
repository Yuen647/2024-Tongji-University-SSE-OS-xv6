#include "kernel/types.h" 
#include "kernel/stat.h"  
#include "user/user.h"    

int main(int argc, char *argv[]) {
    // 检查是否提供了足够的命令行参数
    if (argc < 2) {
        fprintf(2, "Usage: sleep [time]\n"); // 提示正确的使用方法
        exit(1); // 退出程序，返回错误状态码
    }

    // 将第一个命令行参数转换为整数，表示需要睡眠的时间
    int sleep_time = atoi(argv[1]);

    // 调用sleep函数，使程序暂停指定的时间
    sleep(sleep_time);

    // 程序正常退出，返回状态码0
    exit(0);
}
