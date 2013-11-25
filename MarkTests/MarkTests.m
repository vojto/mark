#define EXP_SHORTHAND
#import <Specta/Specta.h>
#import <Expecta/Expecta.h>

SpecBegin(Thing)

describe(@"Thing", ^{
    it(@"does stuff", ^{
        NSLog(@"Doing stuff lol");
        expect(5).to.equal(5);
    });
});

SpecEnd