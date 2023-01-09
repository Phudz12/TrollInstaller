//
//  Helper.m
//  TrollInstaller
//
//  Created by Hornbeck on 1/9/23.
//

#import <Foundation/Foundation.h>
#import <spawn.h>
#import <sys/stat.h>
#import "Helper.h"

NSString* getNSStringFromFile(int fd)
{
    NSMutableString* ms = [NSMutableString new];
    ssize_t num_read;
    char c;
    while((num_read = read(fd, &c, sizeof(c))))
    {
        [ms appendString:[NSString stringWithFormat:@"%c", c]];
    }
    return ms.copy;
}

int runBinary(NSString* path, NSArray* args, NSString** output)
{
    NSMutableArray* argsM = args.mutableCopy;
    [argsM insertObject:path.lastPathComponent atIndex:0];
    
    NSUInteger argCount = [argsM count];
    char **argsC = (char **)malloc((argCount + 1) * sizeof(char*));

    for (NSUInteger i = 0; i < argCount; i++)
    {
        argsC[i] = strdup([[argsM objectAtIndex:i] UTF8String]);
    }
    argsC[argCount] = NULL;
    
    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);
    
    int out[2];
    pipe(out);
    posix_spawn_file_actions_adddup2(&action, out[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&action, out[0]);
    
    pid_t task_pid;
    int status = 0;
    int spawnError = posix_spawn(&task_pid, [path UTF8String], &action, NULL, (char* const*)argsC, NULL);
    for (NSUInteger i = 0; i < argCount; i++)
    {
        free(argsC[i]);
    }
    free(argsC);
    
    if(spawnError != 0)
    {
        NSLog(@"posix_spawn error %d\n", spawnError);
        return spawnError;
    }
    
    do
    {
        if (waitpid(task_pid, &status, 0) != -1) {
            //printf("Child status %dn", WEXITSTATUS(status));
        } else
        {
            perror("waitpid");
            return -222;
        }
    } while (!WIFEXITED(status) && !WIFSIGNALED(status));
    
    close(out[1]);
    
    if(output)
    {
        *output = getNSStringFromFile(out[0]);
    }
    
    return WEXITSTATUS(status);
}
