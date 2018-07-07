//
//  NSObject+GICDataContext.h
//  GICXMLLayout
//
//  Created by 龚海伟 on 2018/7/4.
//

#import <Foundation/Foundation.h>

@interface NSObject (GICDataContext)
/**
 数据上下文
 */
@property (nonatomic,strong)id gic_DataContenxt;

/**
 是否自动继承父节点的数据源。默认yes
 如果设为 no，那么只有在显示设置DataContenxt的情况下才会触发绑定更新
 */
@property (nonatomic,assign)BOOL gic_isAutoInheritDataModel;

/**
 更新数据源
 */
-(void)gic_updateUpdateContext:(id)superDataContenxt;
@end
