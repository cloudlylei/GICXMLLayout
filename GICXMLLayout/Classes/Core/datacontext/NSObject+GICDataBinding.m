//
//  NSObject+GICDataBinding.m
//  GICXMLLayout
//
//  Created by 龚海伟 on 2018/7/4.
//

#import "NSObject+GICDataBinding.h"
#import "NSObject+GICDataContext.h"
#import <objc/runtime.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import "GICDataContext+JavaScriptExtension.h"


/**
 专门提供给data-model做绑定用的。对于data-model的绑定，绑定类型固定是one-way
 */
@interface GICDataModelBinding_ : GICDataBinding

@end

@implementation GICDataModelBinding_
-(GICBingdingMode)bingdingMode{
    return GICBingdingMode_OneWay;
}

-(void)refreshExpression{
    if(!self.isInitBinding){
        @weakify(self)
        [[self.dataSource rac_valuesAndChangesForKeyPath:[self.target gic_dataPathKey] options:NSKeyValueObservingOptionNew observer:nil] subscribeNext:^(RACTwoTuple<id,NSDictionary *> * _Nullable x) {
            @strongify(self)
            [self.target gic_updateDataContext:self.dataSource];
        }];
    }
}
@end


@interface NSObject (GICDataBinding2)
@property (nonatomic,strong)GICDataModelBinding_ *gic_dataModelBinding;
@end


@implementation NSObject (GICDataBinding)
-(NSArray<GICDataBinding *> *)gic_Bindings{
    return objc_getAssociatedObject(self, "gic_Bindings");
}

-(void)setGic_dataPathKey:(NSString *)gic_dataPathKey{
    objc_setAssociatedObject(self, "gic_dataPathKey", gic_dataPathKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString *)gic_dataPathKey{
    return objc_getAssociatedObject(self, "gic_dataPathKey");
}

-(void)gic_addBinding:(GICDataBinding *)binding{
    if(binding==nil)
        return;
    NSMutableArray<GICDataBinding *> * bindings= (NSMutableArray<GICDataBinding *> *)self.gic_Bindings;
    if(bindings==nil){
        bindings = [NSMutableArray array];
        objc_setAssociatedObject(self, "gic_Bindings", bindings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [bindings addObject:binding];
}

-(void)setGic_dataModelBinding:(GICDataModelBinding_ *)gic_dataModelBinding{
    objc_setAssociatedObject(self, "gic_dataModelBinding", gic_dataModelBinding, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(GICDataModelBinding_ *)gic_dataModelBinding{
    return objc_getAssociatedObject(self, "gic_dataModelBinding");
}



-(void)gic_updateDataContext:(id)superDataContenxt{
    if([superDataContenxt isKindOfClass:[JSManagedValue class]]){//js 数据源
        // 这部分逻辑完全交与扩展方法即可
        [self gic_updateDataContextFromJsValue:superDataContenxt];
        return;
    }
    if(self.gic_dataPathKey && ![superDataContenxt isKindOfClass:[NSArray class]]){ //以防array 无法获取value
        id v = [superDataContenxt valueForKey:self.gic_dataPathKey];
        if(![GICUtils isNull:v]){
            if(self.gic_DataContext !=v){
                [self setGic_DataContext:v updateBinding:NO];
                // 创建绑定
                GICDataModelBinding_ *tmp = [GICDataModelBinding_ new];;
                tmp.target = self;
                self.gic_dataModelBinding = tmp;
                [tmp gic_updateDataContext:superDataContenxt];
                // 以便更新当前object的绑定
                superDataContenxt = v;
            }else{
                return;
            }
        }else{
            self.gic_dataModelBinding = nil;
            [self setGic_DataContext:v updateBinding:NO];
            superDataContenxt = v;
        }
    }
    for(GICDataBinding *b in self.gic_Bindings){
        [b gic_updateDataContext:superDataContenxt];
    }
    for(GICBehavior *d in self.gic_Behaviors.behaviors){
        [d gic_updateDataContext:superDataContenxt];
    }
    
    for(NSObject *sub in [self performSelector:@selector(gic_subElements)]){
        if(sub.gic_isAutoInheritDataModel){
            [sub gic_updateDataContext:superDataContenxt];
        }
    }
}
@end

