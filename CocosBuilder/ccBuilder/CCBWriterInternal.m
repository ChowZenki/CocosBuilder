/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "CCBWriterInternal.h"
#import "CCBReaderInternalV1.h"
#import "NodeInfo.h"
#import "PlugInNode.h"
#import "TexturePropertySetter.h"

@implementation CCBWriterInternal


- (void)dealloc
{
    [super dealloc];
}

#pragma mark Shortcuts for serializing properties

+ (id) serializePoint:(CGPoint)pt
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:pt.x],
            [NSNumber numberWithFloat:pt.y],
            nil];
}

+ (id) serializePoint:(CGPoint)pt lock:(BOOL)lock
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:pt.x],
            [NSNumber numberWithFloat:pt.y],
            [NSNumber numberWithBool:lock],
            nil];
}

+ (id) serializeSize:(CGSize)size
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:size.width],
            [NSNumber numberWithFloat:size.height],
            nil];
}

+ (id) serializeBoolPairX:(BOOL)x Y:(BOOL)y
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithBool:x],
            [NSNumber numberWithBool:y],
            nil];
}

+ (id) serializeFloat:(float)f
{
    return [NSNumber numberWithFloat:f];
}

+ (id) serializeInt:(float)d
{
    return [NSNumber numberWithInt:d];
}

+ (id) serializeBool:(float)b
{
    return [NSNumber numberWithBool:b];
}

+ (id) serializeSpriteFrame:(NSString*)spriteFile sheet:(NSString*)spriteSheetFile
{
    if (!spriteFile)
    {
        spriteFile = @"";
    }
    if (!spriteSheetFile || [spriteSheetFile isEqualToString:kCCBUseRegularFile])
    {
        spriteSheetFile = @"";
    }
    return [NSArray arrayWithObjects:spriteSheetFile, spriteFile, nil];
}

+ (id) serializeAnimation:(NSString*)spriteFile file:(NSString*)spriteSheetFile
{
    if (!spriteFile)
    {
        spriteFile = @"";
    }
    if (!spriteSheetFile || [spriteSheetFile isEqualToString:kCCBUseRegularFile])
    {
        spriteSheetFile = @"";
    }
    return [NSArray arrayWithObjects:spriteSheetFile, spriteFile, nil];
}

+ (id) serializeColor3:(ccColor3B)c
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithInt:c.r],
            [NSNumber numberWithInt:c.g],
            [NSNumber numberWithInt:c.b],
            nil];
}

+ (id) serializeColor4:(ccColor4B)c
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithInt:c.r],
            [NSNumber numberWithInt:c.g],
            [NSNumber numberWithInt:c.b],
            [NSNumber numberWithInt:c.a],
            nil];
}

+ (id) serializeColor4F:(ccColor4F)c
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:c.r],
            [NSNumber numberWithFloat:c.g],
            [NSNumber numberWithFloat:c.b],
            [NSNumber numberWithFloat:c.a],
            nil];
}

+ (id) serializeBlendFunc:(ccBlendFunc)bf
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithInt:bf.src],
            [NSNumber numberWithInt:bf.dst],
            nil];
}

#pragma mark Writer

+ (NSMutableDictionary*) dictionaryFromCCObject:(CCNode *)node
{
    NodeInfo* info = node.userObject;
    PlugInNode* plugIn = info.plugIn;
    NSMutableDictionary* extraProps = info.extraProps;
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSMutableArray* props = [NSMutableArray array];
    
    // Get list of properties to exclude from save (if any)
    NSArray* excludeProps = NULL;
    if ([node respondsToSelector:@selector(ccbExcludePropertiesForSave)])
    {
        excludeProps = [node performSelector:@selector(ccbExcludePropertiesForSave)];
    }
    
    NSMutableArray* plugInProps = plugIn.nodeProperties;
    int plugInPropsCount = [plugInProps count];
    for (int i = 0; i < plugInPropsCount; i++)
    {
        NSMutableDictionary* propInfo = [plugInProps objectAtIndex:i];
        NSString* type = [propInfo objectForKey:@"type"];
        NSString* name = [propInfo objectForKey:@"name"];
        NSString* platform = [propInfo objectForKey:@"platform"];
        id serializedValue;
        
        // Check if this property should be excluded
        if (excludeProps && [excludeProps indexOfObject:name] != NSNotFound)
        {
            continue;
        }
        
        // Ignore separators and graphical stuff
        if ([type isEqualToString:@"Separator"]
            || [type isEqualToString:@"SeparatorSub"]
            || [type isEqualToString:@"StartStop"])
        {
            continue;
        }
        
        // Handle different type of properties
        if ([plugIn dontSetInEditorProperty:name])
        {
            // Get the serialized value from the extra props
            serializedValue = [extraProps objectForKey:name];
        }
        else if ([type isEqualToString:@"Position"]
            || [type isEqualToString:@"Point"]
            || [type isEqualToString:@"PointLock"])
        {
			CGPoint pt = NSPointToCGPoint( [[node valueForKey:name] pointValue] );
            serializedValue = [CCBWriterInternal serializePoint:pt];
        }
        else if ([type isEqualToString:@"Size"])
        {
			CGSize size = NSSizeToCGSize( [[node valueForKey:name] sizeValue] );
            serializedValue = [CCBWriterInternal serializeSize:size];
        }
        else if ([type isEqualToString:@"Scale"])
        {
            float x = [[node valueForKey:[NSString stringWithFormat:@"%@X",name]] floatValue];
            float y = [[node valueForKey:[NSString stringWithFormat:@"%@Y",name]] floatValue];
            serializedValue = [CCBWriterInternal serializePoint:ccp(x,y)];
        }
        else if ([type isEqualToString:@"ScaleLock"])
        {
            float x = [[node valueForKey:[NSString stringWithFormat:@"%@X",name]] floatValue];
            float y = [[node valueForKey:[NSString stringWithFormat:@"%@Y",name]] floatValue];
            BOOL lock = [[extraProps objectForKey:[NSString stringWithFormat:@"%@Lock",name]] boolValue];
            serializedValue = [CCBWriterInternal serializePoint:ccp(x,y) lock:lock];
        }
        else if ([type isEqualToString:@"Float"]
                 || [type isEqualToString:@"Degrees"])
        {
            float f = [[node valueForKey:name] floatValue];
            serializedValue = [CCBWriterInternal serializeFloat:f];
        }
        else if ([type isEqualToString:@"FloatVar"])
        {
            float x = [[node valueForKey:name] floatValue];
            float y = [[node valueForKey:[NSString stringWithFormat:@"%@Var",name]] floatValue];
            serializedValue = [CCBWriterInternal serializePoint:ccp(x,y)];
        }
        else if ([type isEqualToString:@"Integer"]
                 || [type isEqualToString:@"IntegerLabeled"]
                 || [type isEqualToString:@"Byte"])
        {
            int d = [[node valueForKey:name] intValue];
            serializedValue = [CCBWriterInternal serializeInt:d];
        }
        else if ([type isEqualToString:@"Check"])
        {
            BOOL check = [[node valueForKey:name] boolValue];
            serializedValue = [CCBWriterInternal serializeBool:check];
        }
        else if ([type isEqualToString:@"Flip"])
        {
            BOOL x = [[node valueForKey:[NSString stringWithFormat:@"%@X",name]] boolValue];
            BOOL y = [[node valueForKey:[NSString stringWithFormat:@"%@Y",name]] boolValue];
            serializedValue = [CCBWriterInternal serializeBoolPairX:x Y:y];
        }
        else if ([type isEqualToString:@"SpriteFrame"])
        {
            NSString* spriteFile = [extraProps objectForKey:name];
            NSString* spriteSheetFile = [extraProps objectForKey:[NSString stringWithFormat:@"%@Sheet",name]];
            serializedValue = [CCBWriterInternal serializeSpriteFrame:spriteFile sheet:spriteSheetFile];
        }
        else if ([type isEqualToString:@"Animation"])
        {
            NSString* animation = [extraProps objectForKey:name];
            NSString* animationFile = [extraProps objectForKey:[NSString stringWithFormat:@"%@Animation",name]];
            serializedValue = [CCBWriterInternal serializeAnimation:animation file:animationFile];
        }		
        else if ([type isEqualToString:@"Texture"])
        {
            NSString* spriteFile = [extraProps objectForKey:name];
            if (!spriteFile) spriteFile = @"";
            
            serializedValue = spriteFile;
        }
        else if ([type isEqualToString:@"Color3"])
        {
            NSValue* colorValue = [node valueForKey:name];
            ccColor3B c;
            [colorValue getValue:&c];
            serializedValue = [CCBWriterInternal serializeColor3:c];
        }
        else if ([type isEqualToString:@"Color4FVar"])
        {
            NSValue* cValue = NULL;
            NSValue* cVarValue = NULL;
            NSString* nameVar = [NSString stringWithFormat:@"%@Var",name];
            cValue = [node valueForKey:name];
            cVarValue = [node valueForKey:nameVar];
            ccColor4F c;
            ccColor4F cVar;
            [cValue getValue:&c];
            [cVarValue getValue:&cVar];
            
            serializedValue = [NSArray arrayWithObjects:
                               [CCBWriterInternal serializeColor4F:c],
                               [CCBWriterInternal serializeColor4F:cVar],
                               nil];
        }
        else if ([type isEqualToString:@"Blendmode"])
        {
            NSValue* blendValue = [node valueForKey:name];
            ccBlendFunc bf;
            [blendValue getValue:&bf];
            serializedValue = [CCBWriterInternal serializeBlendFunc:bf];
        }
        else if ([type isEqualToString:@"FntFile"])
        {
            NSString* str = [TexturePropertySetter fontForNode:node andProperty:name];
            if (!str) str = @"";
            serializedValue = str;
        }
        else if ([type isEqualToString:@"Text"]
                 || [type isEqualToString:@"String"])
        {
            NSString* str = [node valueForKey:name];
            if (!str) str = @"";
            serializedValue = str;
        }
        else if ([type isEqualToString:@"FontTTF"])
        {
            NSString* str = [node valueForKey:name];
            if (!str) str = @"";
            serializedValue = str;
        }
        else if ([type isEqualToString:@"Block"])
        {
            NSString* selector = [extraProps objectForKey:name];
            NSNumber* target = [extraProps objectForKey:[NSString stringWithFormat:@"%@Target",name]];
            if (!selector) selector = @"";
            if (!target) target = [NSNumber numberWithInt:0];
            serializedValue = [NSArray arrayWithObjects:
                               selector,
                               target,
                               nil];
        }
        else if ([type isEqualToString:@"BlockCCControl"])
        {
            NSString* selector = [extraProps objectForKey:name];
            NSNumber* target = [extraProps objectForKey:[NSString stringWithFormat:@"%@Target",name]];
            NSNumber* ctrlEvts = [extraProps objectForKey:[NSString stringWithFormat:@"%@CtrlEvts",name]];
            if (!selector) selector = @"";
            if (!target) target = [NSNumber numberWithInt:0];
            if (!ctrlEvts) ctrlEvts = [NSNumber numberWithInt:0];
            serializedValue = [NSArray arrayWithObjects:
                               selector,
                               target,
                               ctrlEvts,
                               nil];
        }
        else if ([type isEqualToString:@"CCBFile"])
        {
            NSString* spriteFile = [extraProps objectForKey:name];
            if (!spriteFile) spriteFile = @"";
            serializedValue = spriteFile;
        }
        else
        {
            NSLog(@"WARNING Unrecognized property type: %@", type);
        }
        
        NSMutableDictionary* prop = [NSMutableDictionary dictionary];
        [prop setValue:type forKey:@"type"];
        [prop setValue:name forKey:@"name"];
        [prop setValue:serializedValue forKey:@"value"];
        if (platform) [prop setValue:platform forKey:@"platform"];
        
        [props addObject:prop];
    }
    
    NSString* baseClass = plugIn.nodeClassName;
    
    // Children
    NSMutableArray* children = [NSMutableArray array];
    
    // Visit all children of this node
    if (plugIn.canHaveChildren)
    {
        for (int i = 0; i < [[node children] count]; i++)
        {
            [children addObject:[CCBWriterInternal dictionaryFromCCObject:[[node children] objectAtIndex:i]]];
        }
    }
    
    // Create node
    [dict setObject:props forKey:@"properties"];
    [dict setObject:baseClass forKey:@"baseClass"];
    [dict setObject:children forKey:@"children"];
    
    // Add code connection props
    NSString* customClass = [extraProps objectForKey:@"customClass"];
    if (!customClass) customClass = @"";
    NSString* memberVarName = [extraProps objectForKey:@"memberVarAssignmentName"];
    if (!memberVarName) memberVarName = @"";
    int memberVarType = [[extraProps objectForKey:@"memberVarAssignmentType"] intValue];
    
    [dict setObject:customClass forKey:@"customClass"];
    [dict setObject:memberVarName forKey:@"memberVarAssignmentName"];
    [dict setObject:[NSNumber numberWithInt:memberVarType] forKey:@"memberVarAssignmentType"];
    
    return dict;
}

@end
