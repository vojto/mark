#define EXP_SHORTHAND
#import <Specta/Specta.h>
#import <Expecta/Expecta.h>

#import "MKFileSystemSyncService.h"
#import "MKNote.h"

SpecBegin(MKFileSystemSyncService)

describe(@"MKFileSystemSyncService", ^{
    __block MKFileSystemSyncService *service;
    __block NSManagedObjectContext *context;
    __block NSUserDefaults *defaults;
    
    beforeAll(^{
        [MagicalRecord setDefaultModelFromClass:[self class]];
        [MagicalRecord setupCoreDataStackWithInMemoryStore];
        context = [NSManagedObjectContext defaultContext];
        defaults = [NSUserDefaults standardUserDefaults];
    });
    
    it(@"loads base path from defaults", ^{
        [defaults setObject:@"test" forKey:@"filesystemPath"];
        service = [[MKFileSystemSyncService alloc] initWithContext:context];
        expect(service.basePath).to.equal(@"test");
        service = nil;
    });
    
    it(@"updates base path after changing defaults", ^{
        service = [[MKFileSystemSyncService alloc] initWithContext:context];
        [defaults setObject:@"test2" forKey:@"filesystemPath"];
        expect(service.basePath).to.equal(@"test2");
    });
});

SpecEnd