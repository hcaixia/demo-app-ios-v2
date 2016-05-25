//
//  RCDataBaseManager.m
//  RCloudMessage
//
//  Created by 杜立召 on 15/6/3.
//  Copyright (c) 2015年 dlz. All rights reserved.
//

#import "RCDataBaseManager.h"
#import "RCDLoginInfo.h"
#import "RCDUserInfo.h"
#import "RCDHttpTool.h"
#import "DBHelper.h"

@interface RCDataBaseManager ()

//@property (nonatomic, strong) dispatch_queue_t demoDBQueue;

@end

@implementation RCDataBaseManager

static NSString * const userTableName = @"USERTABLE";
static NSString * const groupTableName = @"GROUPTABLEV2";
static NSString * const friendTableName = @"FRIENDTABLE";
static NSString * const blackTableName = @"BLACKTABLE";

+ (RCDataBaseManager*)shareInstance
{
    static RCDataBaseManager* instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
        [instance CreateUserTable];
//        instance.demoDBQueue = dispatch_queue_create("cn.rongcloud.demo.dbqueue", NULL);
    });
    return instance;
}

//创建用户存储表
-(void)CreateUserTable
{
    FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
    if (queue==nil) {
        return;
    }
    [queue inDatabase:^(FMDatabase *db) {
        if (![DBHelper isTableOK: userTableName withDB:db]) {
            NSString *createTableSQL = @"CREATE TABLE USERTABLE (id integer PRIMARY KEY autoincrement, userid text,name text, portraitUri text)";
            [db executeUpdate:createTableSQL];
            NSString *createIndexSQL=@"CREATE unique INDEX idx_userid ON USERTABLE(userid);";
            [db executeUpdate:createIndexSQL];
        }
        
        if (![DBHelper isTableOK: groupTableName withDB:db]) {
            NSString *createTableSQL = @"CREATE TABLE GROUPTABLEV2 (id integer PRIMARY KEY autoincrement, groupId text,name text, portraitUri text,inNumber text,maxNumber text ,introduce text ,creatorId text,creatorTime text, isJoin text)";
            [db executeUpdate:createTableSQL];
            NSString *createIndexSQL=@"CREATE unique INDEX idx_groupid ON GROUPTABLEV2(groupId);";
            [db executeUpdate:createIndexSQL];
        }
        if (![DBHelper isTableOK: friendTableName withDB:db]) {
            NSString *createTableSQL = @"CREATE TABLE FRIENDTABLE (id integer PRIMARY KEY autoincrement, userid text,name text, portraitUri text)";
            [db executeUpdate:createTableSQL];
            NSString *createIndexSQL=@"CREATE unique INDEX idx_friendId ON FRIENDTABLE(userid);";
            [db executeUpdate:createIndexSQL];
        }
        
        if (![DBHelper isTableOK: blackTableName withDB:db]) {
            NSString *createTableSQL = @"CREATE TABLE BLACKTABLE (id integer PRIMARY KEY autoincrement, userid text,name text, portraitUri text)";
            [db executeUpdate:createTableSQL];
            NSString *createIndexSQL=@"CREATE unique INDEX idx_blackId ON BLACKTABLE(userid);";
            [db executeUpdate:createIndexSQL];
        }
    }];
    
}

//存储用户信息
-(void)insertUserToDB:(RCUserInfo*)user
{
//    //dispatch_async(self.demoDBQueue, ^{
        NSString *insertSql = @"REPLACE INTO USERTABLE (userid, name, portraitUri) VALUES (?, ?, ?)";
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:insertSql,user.userId,user.name,user.portraitUri];
        }];
//    //});
}

//插入黑名单列表
-(void)insertBlackListToDB:(RCUserInfo*)user{
    //dispatch_async(self.demoDBQueue, ^{
        NSString *insertSql = @"REPLACE INTO BLACKTABLE (userid, name, portraitUri) VALUES (?, ?, ?)";
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:insertSql,user.userId,user.name,user.portraitUri];
        }];
    //});
}

//获取黑名单列表
- (void)getBlackList:(void (^)(NSArray *allBlackList))completion
{
    //dispatch_async(self.demoDBQueue, ^{
        NSMutableArray *allBlackList = [NSMutableArray new];
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM BLACKTABLE"];
            while ([rs next]) {
                RCUserInfo *model;
                model = [[RCUserInfo alloc] init];
                model.userId = [rs stringForColumn:@"userid"];
                model.name = [rs stringForColumn:@"name"];
                model.portraitUri = [rs stringForColumn:@"portraitUri"];
                [allBlackList addObject:model];
            }
            [rs close];
        }];
        completion(allBlackList);
    //});
}

//移除黑名单
- (void)removeBlackList:(NSString *)userId{
    //dispatch_async(self.demoDBQueue, ^{
        NSString *deleteSql =[NSString stringWithFormat: @"DELETE FROM BLACKTABLE WHERE userid=%@",userId];
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        if (queue==nil) {
            return ;
        }
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:deleteSql];
        }];
    //});
}

//清空黑名单缓存数据
-(void)clearBlackListData
{
    //dispatch_async(self.demoDBQueue, ^{
        NSString *deleteSql = @"DELETE FROM BLACKTABLE";
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        if (queue==nil) {
            return ;
        }
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:deleteSql];
        }];
    //});
}

//从表中获取用户信息
-(void)getUserByUserId:(NSString*)userId
            completion:(void (^)(RCUserInfo *userInfo))completion
{
    //dispatch_async(self.demoDBQueue, ^{
        __block RCUserInfo *model = nil;
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        if (queue==nil) {
            completion(nil);
        }
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM USERTABLE where userid = ?",userId];
            while ([rs next]) {
                model = [[RCUserInfo alloc] init];
                model.userId = [rs stringForColumn:@"userid"];
                model.name = [rs stringForColumn:@"name"];
                model.portraitUri = [rs stringForColumn:@"portraitUri"];
            }
            [rs close];
        }];
        completion(model);
    //});
}

//从表中获取所有用户信息
-(void)getAllUserInfo:(void (^)(NSArray *allUserInfoList))completion
{
    //dispatch_async(self.demoDBQueue, ^{
        NSMutableArray *allUsers = [NSMutableArray new];
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM USERTABLE"];
            while ([rs next]) {
                RCUserInfo *model;
                model = [[RCUserInfo alloc] init];
                model.userId = [rs stringForColumn:@"userid"];
                model.name = [rs stringForColumn:@"name"];
                model.portraitUri = [rs stringForColumn:@"portraitUri"];
                [allUsers addObject:model];
            }
            [rs close];
        }];
        completion(allUsers);
    //});
}
//存储群组信息
-(void)insertGroupToDB:(RCDGroupInfo *)group
{
    //dispatch_async(self.demoDBQueue, ^{
        if(group == nil || [group.groupId length]<1)
            return;
        
        NSString *insertSql = @"REPLACE INTO GROUPTABLEV2 (groupId, name,portraitUri,inNumber,maxNumber,introduce,creatorId,creatorTime,isJoin) VALUES (?,?,?,?,?,?,?,?,?)";
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        if (queue==nil) {
            return;
        }
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:insertSql,group.groupId, group.groupName,group.portraitUri,group.number,group.maxNumber,group.introduce,group.creatorId,group.creatorTime,[NSString stringWithFormat:@"%d",group.isJoin]];
        }];
    //});
}
//从表中获取群组信息
-(void)getGroupByGroupId:(NSString*)groupId
              completion:(void (^)(RCDGroupInfo *groupInfo))completion
{
    //dispatch_async(self.demoDBQueue, ^{
        __block RCDGroupInfo *model = nil;
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM GROUPTABLEV2 where groupId = ?",groupId];
            while ([rs next]) {
                model = [[RCDGroupInfo alloc] init];
                model.groupId = [rs stringForColumn:@"groupId"];
                model.groupName = [rs stringForColumn:@"name"];
                model.portraitUri = [rs stringForColumn:@"portraitUri"];
                model.number=[rs stringForColumn:@"inNumber"];
                model.maxNumber=[rs stringForColumn:@"maxNumber"];
                model.introduce=[rs stringForColumn:@"introduce"];
                model.creatorId=[rs stringForColumn:@"creatorId"];
                model.creatorTime=[rs stringForColumn:@"creatorTime"];
                model.isJoin=[rs boolForColumn:@"isJoin"];
                
            }
            [rs close];
        }];
        completion(model);
    //});
}

//从表中获取所有群组信息
-(void)getAllGroup:(void (^)(NSArray *allGroupInfoList))completion
{
    //dispatch_async(self.demoDBQueue, ^{
        NSMutableArray *allUsers = [NSMutableArray new];
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM GROUPTABLEV2 ORDER BY groupId"];
            while ([rs next]) {
                RCDGroupInfo *model;
                model = [[RCDGroupInfo alloc] init];
                model.groupId = [rs stringForColumn:@"groupId"];
                model.groupName = [rs stringForColumn:@"name"];
                model.portraitUri = [rs stringForColumn:@"portraitUri"];
                model.number=[rs stringForColumn:@"inNumber"];
                model.maxNumber=[rs stringForColumn:@"maxNumber"];
                model.introduce=[rs stringForColumn:@"introduce"];
                model.creatorId=[rs stringForColumn:@"creatorId"];
                model.creatorTime=[rs stringForColumn:@"creatorTime"];
                model.isJoin=[rs boolForColumn:@"isJoin"];
                [allUsers addObject:model];
            }
            [rs close];
        }];
        completion(allUsers);
    //});
}

//存储好友信息
-(void)insertFriendToDB:(RCUserInfo *)friend
{
    //dispatch_async(self.demoDBQueue, ^{
        NSString *insertSql = @"REPLACE INTO FRIENDTABLE (userid, name, portraitUri) VALUES (?, ?, ?)";
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:insertSql,friend.userId, friend.name, friend.portraitUri];
        }];
    //});
}

//从表中获取所有好友信息 //RCUserInfo
-(void)getAllFriends:(void (^)(NSArray *allFriendUserInfoList))completion
{
    //dispatch_async(self.demoDBQueue, ^{
        NSMutableArray *allUsers = [NSMutableArray new];
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM FRIENDTABLE"];
            while ([rs next]) {
                RCUserInfo *model;
                model = [[RCUserInfo alloc] init];
                model.userId = [rs stringForColumn:@"userid"];
                model.name = [rs stringForColumn:@"name"];
                model.portraitUri = [rs stringForColumn:@"portraitUri"];
                [allUsers addObject:model];
            }
            [rs close];
        }];
        completion(allUsers);
    //});
}

//清空群组缓存数据
-(void)clearGroupsData
{
    //dispatch_async(self.demoDBQueue, ^{
        NSString *deleteSql = @"DELETE FROM GROUPTABLEV2";
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        if (queue==nil) {
            return ;
        }
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:deleteSql];
        }];
    //});
}

//清空好友缓存数据
-(void)clearFriendsData
{
    //dispatch_async(self.demoDBQueue, ^{
        NSString *deleteSql = @"DELETE FROM FRIENDTABLE";
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        if (queue==nil) {
            return ;
        }
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:deleteSql];
        }];
    //});
}


-(void)deleteFriendFromDB:(NSString *)userId;
{
    //dispatch_async(self.demoDBQueue, ^{
        NSString *deleteSql =[NSString stringWithFormat: @"DELETE FROM FRIENDTABLE WHERE userid=%@",userId];
        FMDatabaseQueue *queue = [DBHelper getDatabaseQueue];
        if (queue==nil) {
            return ;
        }
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:deleteSql];
        }];
    //});
}

@end
