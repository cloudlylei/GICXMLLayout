//
//  GICDirectiveFor.m
//  GICXMLLayout
//
//  Created by 龚海伟 on 2018/7/6.
//

#import "GICDirectiveFor.h"
#import "NSObject+GICDataBinding.h"
#import "NSObject+GICDataContext.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import "GICTemplateRef.h"

@implementation GICDirectiveFor
+(NSString *)gic_elementName{
    return @"for";
}

-(void)gic_parseSubElements:(NSArray<GDataXMLElement *> *)children{
    if(children.count==1){
        self->xmlDoc =  [[GDataXMLDocument alloc] initWithRootElement:children[0]];
    }
}

-(BOOL)gic_parseOnlyOneSubElement{
    return YES;
}

-(void)gic_updateDataContext:(id)superDataContenxt{
    [super gic_updateDataContext:superDataContenxt];
    [self updateDataSource:superDataContenxt];
}

-(void)updateDataSource:(id)dataSource{
    //TODO: 对data-model的支持
    if([dataSource isKindOfClass:[NSArray class]] && [self.target respondsToSelector:@selector(gic_addSubElement:)]){
        [self.target gic_removeAllSubElements];//更新数据源以后需要清空原来是数据，然后重新添加数据
        for(id data in dataSource){
            [self addAElement:data];
        }
        if([dataSource isKindOfClass:[NSMutableArray class]]){
            @weakify(self)
            [[dataSource rac_signalForSelector:@selector(addObject:)] subscribeNext:^(RACTuple * _Nullable x) {
                @strongify(self)
                [self addAElement:x[0]];
            }];
            
            [[dataSource rac_signalForSelector:@selector(addObjectsFromArray:)] subscribeNext:^(RACTuple * _Nullable x) {
                @strongify(self)
                for(id data in x[0]){
                    [self addAElement:data];
                }
            }];
        }
    }
}

-(void)addAElement:(id)data{
    NSObject *childElement = [GICXMLLayout createElement:[self->xmlDoc rootElement]];
    if([childElement isKindOfClass:[GICTemplateRef class]]){
        childElement = [(GICTemplateRef *)childElement parseTemplateFromTarget:self.target];
    }
    childElement.gic_isAutoInheritDataModel = NO;
    childElement.gic_DataContenxt = data;
    [self.target gic_addSubElement:childElement];
}
@end