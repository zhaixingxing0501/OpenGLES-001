//
//  ViewController.m
//  OpenGLES
//
//  Created by zhaixingxing on 2020/7/25.
//  Copyright © 2020 zhaixingxing. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface ViewController ()<GLKViewDelegate>
{
    EAGLContext *_context;
    GLKBaseEffect *_effect;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //1. 设置GLKView
    [self setupConfigure];

    //2. 设置顶点数据
    [self setupVertexData];

    //3. 设置纹理
    [self setupTexture];
}

#pragma mark -- 设置纹理 --
- (void)setupTexture {
    //1. 获取图片路径
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"tiger" ofType:@"jpg"];

    //2. 设置纹理参数
    //纹理坐标原点是左下角,但是图片显示原点应该是左上角.
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@1, GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];

    //3.使用苹果GLKit 提供GLKBaseEffect 完成着色器工作(顶点/片元)
    _effect = [[GLKBaseEffect alloc] init];
    _effect.texture2d0.enabled = GL_TRUE;
    _effect.texture2d0.name = textureInfo.name;

    //4. 设置投影
    CGFloat aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45), aspect, 0.1, 100.0);
    _effect.transform.projectionMatrix = projectionMatrix;

    GLKMatrix4 modelviewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -4.0);
    _effect.transform.modelviewMatrix = modelviewMatrix;
}

#pragma mark -- 初始化顶点数据 --
- (void)setupVertexData {
    //1. 顶点数据(顶点坐标, 纹理坐标)(内存中)
    //2. 2个三角形,6个顶点
    //  前三个顶点数据(xyz), 后面两个纹理数据(st)
    GLfloat vertexData[] = {
        0.5,  -0.5,  0.0f,   1.0f, 0.0f,      //右下
        0.5,  0.5,   0.0f,   1.0f, 1.0f,      //右上
        -0.5, 0.5,   0.0f,   0.0f, 1.0f,      //左上

        0.5,  -0.5,  0.0f,   1.0f, 0.0f,      //右下
        -0.5, 0.5,   0.0f,   0.0f, 1.0f,      //左上
        -0.5, -0.5,  0.0f,   0.0f, 0.0f,      //左下
    };

    //3. 创建顶点缓冲区标识
    GLuint bufferId;
    glGenBuffers(1, &bufferId);
    //4. 绑定顶点缓冲区标识
    glBindBuffer(GL_ARRAY_BUFFER, bufferId);
    //5. 将顶点数组的数据copy到顶点缓冲区(顶点数据(CPU) --> 顶点缓存区(GPU))
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);

    /*
      (1)在iOS中, 默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的.
      意味着,顶点数据在着色器端(服务端)是不可用的. 即使你已经使用glBufferData方法,将顶点数据从内存拷贝到顶点缓存区中(GPU显存中).
      所以, 必须由glEnableVertexAttribArray 方法打开通道.指定访问属性.才能让顶点着色器能够访问到从CPU复制到GPU的数据.
      注意: 数据在GPU端是否可见，即，着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。

     (2)方法简介
     glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr)

     功能: 上传顶点数据到显存的方法（设置合适的方式从buffer里面读取数据）
     参数列表:
         index,指定要修改的顶点属性的索引值,例如
         size, 每次读取数量。（如position是由3个（x,y,z）组成，而颜色是4个（r,g,b,a）,纹理则是2个.）
         type,指定数组中每个组件的数据类型。可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT。
         normalized,指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）
         stride,指定连续顶点属性之间的偏移量。如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0
         ptr指定一个指针，指向数组中第一个顶点属性的第一个组件。初始值为0
      */

    //6. 打开坐标读取通道
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    // 上传顶点数据到显存的方法（设置合适的方式从buffer里面读取数据）
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);

    //7. 打开纹理读取通道
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    //上传纹理数据到显存的方法（设置合适的方式从buffer里面读取数据）
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
}

#pragma mark -- 设置GLKView --
- (void)setupConfigure {
    //1.初始化上下文
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];

    //2. 判断是否创建成功
    if (_context) {
        NSLog(@"content创建成功");
    } else {
        NSLog(@"content创建失败");
    }

    //3. 可以有多个上下文,指定当前上下文
    [EAGLContext setCurrentContext:_context];

    //4. GLKView
    GLKView *view = (GLKView *)self.view;
    view.context = _context;

    /*
       (1). drawableColorFormat: 颜色缓存区格式.
       简介:  OpenGL ES 有一个缓存区，它用以存储将在屏幕中显示的颜色。你可以使用其属性来设置缓冲区中的每个像素的颜色格式。

       GLKViewDrawableColorFormatRGBA8888 = 0,
       默认.缓存区的每个像素的最小组成部分（RGBA）使用8个bit，（所以每个像素4个字节，4*8个bit）。

       GLKViewDrawableColorFormatRGB565,
       如果你的APP允许更小范围的颜色，即可设置这个。会让你的APP消耗更小的资源（内存和处理时间）

       (2). drawableDepthFormat: 深度缓存区格式

       GLKViewDrawableDepthFormatNone = 0,意味着完全没有深度缓冲区
       GLKViewDrawableDepthFormat16,
       GLKViewDrawableDepthFormat24,
       如果你要使用这个属性（一般用于3D游戏），你应该选择GLKViewDrawableDepthFormat16
       或GLKViewDrawableDepthFormat24。这里的差别是使用GLKViewDrawableDepthFormat16
       将消耗更少的资源
       */

    //设置颜色缓冲区
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    //深度 缓冲区
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    //5. 设置背景色
    glClearColor(243 / 255.0, 244 / 255.0, 250 / 255.0, 1);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //1. 清楚颜色
    glClear(GL_COLOR_BUFFER_BIT);

    //2. 准备绘制
    [_effect prepareToDraw];

    //3. 开始绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end
