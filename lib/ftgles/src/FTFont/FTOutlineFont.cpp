/*
 * FTGL - OpenGL font library
 *
 * Copyright (c) 2001-2004 Henry Maddocks <ftgl@opengl.geek.nz>
 * Copyright (c) 2008 Sam Hocevar <sam@zoy.org>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include "config.h"

#include "FTGL/ftgles.h"

#include "FTInternals.h"
#include "FTOutlineFontImpl.h"


//
//  FTOutlineFont
//


FTOutlineFont::FTOutlineFont(char const *fontFilePath) :
    FTFont(new FTOutlineFontImpl(this, fontFilePath))
{}


FTOutlineFont::FTOutlineFont(const unsigned char *pBufferBytes,
                             size_t bufferSizeInBytes) :
    FTFont(new FTOutlineFontImpl(this, pBufferBytes, bufferSizeInBytes))
{}


FTOutlineFont::~FTOutlineFont()
{}


FTGlyph* FTOutlineFont::MakeGlyph(FT_GlyphSlot ftGlyph)
{
#ifndef ANDROID
    FTOutlineFontImpl *myimpl = dynamic_cast<FTOutlineFontImpl *>(impl);
#else
    // No RTTI for you
    FTOutlineFontImpl *myimpl = (FTOutlineFontImpl *)(impl);
#endif
    if(!myimpl)
    {
        return NULL;
    }

    return new FTOutlineGlyph(ftGlyph, myimpl->outset,
                              myimpl->useDisplayLists);
}


//
//  FTOutlineFontImpl
//


FTOutlineFontImpl::FTOutlineFontImpl(FTFont *ftFont, const char* fontFilePath)
: FTFontImpl(ftFont, fontFilePath),
  outset(0.0f)
{
    load_flags = FT_LOAD_NO_HINTING;
	preRendered = false;
}


FTOutlineFontImpl::FTOutlineFontImpl(FTFont *ftFont,
                                     const unsigned char *pBufferBytes,
                                     size_t bufferSizeInBytes)
: FTFontImpl(ftFont, pBufferBytes, bufferSizeInBytes),
  outset(0.0f)
{
    load_flags = FT_LOAD_NO_HINTING;
	preRendered = false;
}


template <typename T>
inline FTPoint FTOutlineFontImpl::RenderI(const T* string, const int len,
                                          FTPoint position, FTPoint spacing,
                                          int renderMode)
{
	FTPoint tmp;
	if (preRendered)
	{
		tmp = FTFontImpl::Render(string, len,
										 position, spacing, renderMode);
	}
	else
	{
		PreRender();
		tmp = FTFontImpl::Render(string, len,
										 position, spacing, renderMode);
		PostRender();
	}

    return tmp;
}


void FTOutlineFontImpl::PreRender()
{
	preRendered = true;
	GLfloat colors[4];
    glDisable(GL_TEXTURE_2D);
    glEnable(GL_LINE_SMOOTH);
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); // GL_ONE
	glBindTexture(GL_TEXTURE_2D, 0);

	glGetFloatv(GL_CURRENT_COLOR, colors);
	ftglColor4f(colors[0], colors[1], colors[2], colors[3]);
	ftglBegin(GL_LINES);
}


void FTOutlineFontImpl::PostRender()
{
	preRendered = false;
	ftglEnd();
}


FTPoint FTOutlineFontImpl::Render(const char * string, const int len,
                                  FTPoint position, FTPoint spacing,
                                  int renderMode)
{
    return RenderI(string, len, position, spacing, renderMode);
}


FTPoint FTOutlineFontImpl::Render(const wchar_t * string, const int len,
                                  FTPoint position, FTPoint spacing,
                                  int renderMode)
{
    return RenderI(string, len, position, spacing, renderMode);
}

