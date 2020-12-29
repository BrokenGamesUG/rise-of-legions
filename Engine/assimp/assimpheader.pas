{ Open Asset Import Library (ASSIMP) Pascal Header




 ---------------------------------------------------------------------------
 Copyright (c) 2012, Steve Hilderbrandt, Necem dot dev at gmx dot net

 All rights reserved.

 Redistribution and use of this software in source and binary forms,
 with or without modification, are permitted provided that the following
 conditions are met:

 * Redistributions of source code must retain the above
 copyright notice, this list of conditions and the
 following disclaimer.

 * Redistributions in binary form must reproduce the above
 copyright notice, this list of conditions and the
 following disclaimer in the documentation and/or other
 materials provided with the distribution.

 * Neither the name of Steve Hilderbrandt, nor the names of its
 contributors may be used to endorse or promote products
 derived from this software without specific prior
 written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ---------------------------------------------------------------------------
 Based on :

 Open Asset Import Library (ASSIMP)
 Copyright (c) 2006-2010, ASSIMP Development Team assimp.sourceforge.net
 3-clause BSD license
}

unit AssimpHeader;

{$I AssimpDefines.inc}

interface

uses
  windows,
  SysUtils,
  Generics.Collections,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.windows;

const
  // Windows
  ASSIMP_LIBNAME             = 'assimp.dll';
  ASSIMP_LIBNAME_ALTERNATIVE = 'assimp_2.dll';

type
  PAiChar = type PAnsiChar;
  TAiChar = type AnsiChar;
  TAiBool = type longint;
  TAiFloat = type single;
  TAiReal = type double;
  TAiEnum32 = type longword;
  TAiUInt = type longword;
  TAiInt = type integer;

  TAiSize_t = type longword;

  PAiFloat = ^TAiFloat;
  PAiUInt = ^TAiUInt;
  PAiInt = ^TAiInt;

const
  AI_RETURN_SUCCESS     = $0;
  AI_RETURN_FAILURE     = -$1;
  AI_RETURN_OUTOFMEMORY = -$3;

const
  AI_FALSE = 0;
  AI_TRUE  = 1;

type
  TAiReturn = type TAiEnum32;

const
  AI_ORIGIN_SET = $0;
  AI_ORIGIN_CUR = $1;
  AI_ORIGIN_END = $2;

type
  TAiOrigin = type TAiEnum32;

const
  AI_DEFAULTLOGSTREAM_FILE     = $1;
  AI_DEFAULTLOGSTREAM_STDOUT   = $2;
  AI_DEFAULTLOGSTREAM_STDERR   = $4;
  AI_DEFAULTLOGSTREAM_DEBUGGER = $8;

type
  TAiDefaultLogStream = type TAiEnum32;

const
  AI_STRING_MAXBYTELEN = 1024;

type
  PAiString = ^TAiString;

  TAiString = packed record
    length : TAiSize_t;
    data : array [0 .. AI_STRING_MAXBYTELEN - 1] of AnsiChar;
    function AsString : string;
  end;

type
  PAiMatrix3x3 = ^TAiMatrix3x3;

  TAiMatrix3x3 = packed record
    a1, a2, a3 : TAiFloat;
    b1, b2, b3 : TAiFloat;
    c1, c2, c3 : TAiFloat;
  end;

  PAiMatrix4x4 = ^TAiMatrix4x4;

  TAiMatrix4x4 = packed record
    a1, a2, a3, a4 : TAiFloat;
    b1, b2, b3, b4 : TAiFloat;
    c1, c2, c3, c4 : TAiFloat;
    d1, d2, d3, d4 : TAiFloat;
    class operator implicit(a : TAiMatrix4x4) : RMatrix;
  end;

  PAiVector2D = ^TAiVector2D;

  TAiVector2D = packed record
    x, y : TAiFloat;
    class operator implicit(a : TAiVector2D) : RVector2;
  end;

  PAiVector3D = ^TAiVector3D;

  TAiVector3D = packed record
    x, y, z : TAiFloat;
    class operator implicit(a : TAiVector3D) : RVector3;
  end;

  PAiColor3D = ^TAiColor3D;

  TAiColor3D = packed record
    r, g, b : TAiFloat;
  end;

  PAiColor4D = ^TAiColor4D;

  TAiColor4D = packed record
    r, g, b, a : TAiFloat;
  end;

  TAiQuaternion = packed record
    w, x, y, z : TAiFloat;
    class operator implicit(a : TAiQuaternion) : RQuaternion;
  end;

const
  AI_BOOL       = 0;
  AI_INT        = 1;
  AI_UINT64     = 2;
  AI_FLOAT      = 3;
  AI_AISTRING   = 4;
  AI_AIVECTOR3D = 5;

type
  PAiMetadataEntry = ^TAiMetadataEntry;
  PPAiMetadataEntry = ^PAiMetadataEntry;

  TAiMetadataEntry = packed record
    mType : TAiEnum32;
    mData : Pointer;
  end;

  PAiMetaData = ^TAiMetaData;
  PPAiMetadata = ^PAiMetaData;

  TAiMetaData = packed record
    mNumProperties : TAiUInt;
    mKeys : PAiString;
    mValues : PAiMetadataEntry;
  end;

const
  AI_MAX_FACE_INDICES            = $7FFF;
  AI_MAX_BONE_WEIGHTS            = $7FFFFFFF;
  AI_MAX_VERTICES                = $7FFFFFFF;
  AI_MAX_FACES                   = $7FFFFFFF;
  AI_MAX_NUMBER_OF_COLOR_SETS    = $8;
  AI_MAX_NUMBER_OF_TEXTURECOORDS = $8;

type
  PPAiFace = ^PAiFace;
  PAiFace = ^TAiFace;

  TAiFace = packed record
    mNumIndices : TAiUInt;
    mIndices : PAiUInt;
    function asArray : TArray<TAiUInt>;
  end;

type
  PAiVertexWeight = ^TAiVertexWeight;

  /// <summary> A single influence of a bone on a vertex.</summary>
  TAiVertexWeight = record
    /// <summary> Index of the vertex which is influenced by the bone.</summary>
    mVertexId : TAiUInt;
    /// <summary> The strength of the influence in the range (0...1).
    /// The influence from all bones at one vertex amounts to 1.</summary>
    mWeight : TAiFloat;
  end;

type
  PPAiBone = ^PAiBone;
  PAiBone = ^TAiBone;

  /// <summary> A single bone of a mesh.
  /// A bone has a name by which it can be found in the frame hierarchy and by
  /// which it can be addressed by animations. In addition it has a number of
  /// influences on vertices.</summary>
  TAiBone = record
    /// <summary> The name of the bone.</summary>
    mName : TAiString;
    /// <summary> The number of vertices affected by this bone
    /// The maximum value for this member is #AI_MAX_BONE_WEIGHTS.</summary>
    mNumWeights : TAiUInt;
    /// <summary> The vertices affected by this bone.</summary>
    mWeights : PAiVertexWeight;
    /// <summary> Matrix that transforms from mesh space to bone space in bind pose.</summary>
    mOffsetMatrix : TAiMatrix4x4;
  end;

const
  AI_PRIMITIVETYPE_POINT      = $1;
  AI_PRIMITIVETYPE_LINE       = $2;
  AI_PRIMITIVETYPE_TRIANGLE   = $4;
  AI_PRIMITIVETYPE_POLYGON    = $8;
  AI_PRIMITIVETYPE_FORCE32BIT = MaxInt;

type
  TAiPrimitiveType = type TAiEnum32;

type
  TAiColor4DArray = array [0 .. AI_MAX_NUMBER_OF_COLOR_SETS - 1] of PAiColor4D;
  TAiTexCoord3DArray = array [0 .. AI_MAX_NUMBER_OF_TEXTURECOORDS - 1] of PAiVector3D;

type
  PPAiAnimMesh = ^PAiAnimMesh;
  PAiAnimMesh = ^TAiAnimMesh;

  TAiAnimMesh = packed record
    mVertices : PAiVector3D;
    mNormals : PAiVector3D;
    mTangents : PAiVector3D;
    mBitangents : PAiVector3D;
    mColors : TAiColor4DArray;
    mTextureCoords : TAiTexCoord3DArray;
    mNumVertices : longword;
  end;

type
  TAiNumUVComponentsArray = array [0 .. AI_MAX_NUMBER_OF_TEXTURECOORDS - 1] of TAiUInt;

type
  PPAiMesh = ^PAiMesh;
  PAiMesh = ^TAiMesh;

  TAiMesh = record
    /// <summary> Bitwise combination of the members of the #aiPrimitiveType enum.
    /// This specifies which types of primitives are present in the mesh.
    /// The "SortByPrimitiveType"-Step can be used to make sure the
    /// output meshes consist of one primitive type each.</summary>
    mPrimitiveTypes : TAiPrimitiveType;
    /// <summary> The number of vertices in this mesh.
    /// This is also the size of all of the per-vertex data arrays.
    /// The maximum value for this member is AI_MAX_VERTICES.</summary>
    mNumVertices : TAiUInt;
    /// <summary> The number of primitives (triangles, polygons, lines) in this  mesh.
    /// This is also the size of the mFaces array.
    /// The maximum value for this member is #AI_MAX_FACES.</summary>
    mNumFaces : TAiUInt;
    /// <summary> Vertex positions.
    /// This array is always present in a mesh. The array is
    /// mNumVertices in size. </summary>
    mVertices : PAiVector3D;

    mNormals : PAiVector3D;
    mTangents : PAiVector3D;
    mBitangents : PAiVector3D;
    /// <summary> Vertex color sets.
    /// A mesh may contain 0 to AI_MAX_NUMBER_OF_COLOR_SETS vertex colors per vertex.
    /// NULL if not present. Each array is mNumVertices in size if present.</summary>
    mColors : TAiColor4DArray;
    /// <summary> Vertex texture coords, also known as UV channels.
    /// A mesh may contain 0 to AI_MAX_NUMBER_OF_TEXTURECOORDS per
    /// vertex. NULL if not present. The array is mNumVertices in size. </summary>
    mTextureCoords : TAiTexCoord3DArray;
    /// <summary> Specifies the number of components for a given UV channel.
    /// Up to three channels are supported (UVW, for accessing volume
    /// or cube maps). If the value is 2 for a given channel n, the
    /// component p.z of mTextureCoords[n][p] is set to 0.0f.
    /// If the value is 1 for a given channel, p.y is set to 0.0f, too.
    /// @note 4D coords are not supported </summary>
    mNumUVComponents : TAiNumUVComponentsArray;
    /// <summary> Each face refers to a number of vertices by their indices.
    /// This array is always present in a mesh, its size is given
    /// in mNumFaces. If the #AI_SCENE_FLAGS_NON_VERBOSE_FORMAT
    /// is NOT set each face references an unique set of vertices.</summary>
    mFaces : PAiFace;
    mNumBones : TAiUInt;
    mBones : PPAiBone;
    mMaterialIndex : TAiUInt;
    mName : TAiString;
    mNumAnimMeshes : TAiUInt;
    mAnimMeshes : PPAiAnimMesh;
  end;

const
  AI_TEXTURE_OP_MULTIPLY  = $0;
  AI_TEXTURE_OP_ADD       = $1;
  AI_TEXTURE_OP_SUBTRACT  = $2;
  AI_TEXTURE_OP_DIVIDE    = $3;
  AI_TEXTURE_OP_SMOOTHADD = $4;
  AI_TEXTURE_OP_SIGNEDADD = $5;

type
  PAiTextureOp = ^TAiTextureOp;
  TAiTextureOp = type TAiEnum32;

const
  AI_TEXTIRE_MAPMODE_WRAP   = $0;
  AI_TEXTIRE_MAPMODE_CLAMP  = $1;
  AI_TEXTIRE_MAPMODE_MIRROR = $2;
  AI_TEXTIRE_MAPMODE_DECAL  = $3;

type
  PAiTextureMapMode = ^TAiTextureMapMode;
  TAiTextureMapMode = type TAiEnum32;

const
  AI_TEXTURE_MAPPING_UV       = $0;
  AI_TEXTURE_MAPPING_SPHERE   = $1;
  AI_TEXTURE_MAPPING_CYLINDER = $2;
  AI_TEXTURE_MAPPING_BOX      = $3;
  AI_TEXTURE_MAPPING_PLANE    = $4;
  AI_TEXTURE_MAPPING_OTHER    = $5;

type
  PAiTextureMapping = ^TAiTextureMapping;
  TAiTextureMapping = type TAiEnum32;

const
  AI_TEXTURE_TYPE_NONDE        = $0;
  AI_TEXTURE_TYPE_DIFFUSE      = $1;
  AI_TEXTURE_TYPE_SPECULAR     = $2;
  AI_TEXTURE_TYPE_AMBIENT      = $3;
  AI_TEXTURE_TYPE_EMISSIVE     = $4;
  AI_TEXTURE_TYPE_HEIGHT       = $5;
  AI_TEXTURE_TYPE_NORMALS      = $6;
  AI_TEXTURE_TYPE_SHININESS    = $7;
  AI_TEXTURE_TYPE_OPACITY      = $8;
  AI_TEXTURE_TYPE_DISPLACEMENT = $9;
  AI_TEXTURE_TYPE_LIGHTMAP     = $A;
  AI_TEXTURE_TYPE_REFLECTION   = $B;
  AI_TEXTURE_TYPE_UNKNOWN      = $C;

type
  TAiTextureType = type TAiEnum32;

const
  AI_SHADING_MODE_FLAT         = $1;
  AI_SHADING_MODE_GOURAUD      = $2;
  AI_SHADING_MODE_PHONG        = $3;
  AI_SHADING_MODE_BLINN        = $4;
  AI_SHADING_MODE_TOON         = $5;
  AI_SHADING_MODE_ORENNAYAR    = $6;
  AI_SHADING_MODE_MINNAERT     = $7;
  AI_SHADING_MODE_COOKTORRANCE = $8;
  AI_SHADING_MODE_NOSHADING    = $9;
  AI_SHADING_MODE_FRESNEL      = $A;

type
  TAiShadingMode = type TAiEnum32;

const
  AI_TEXTURE_FLAGS_INVERT = $1;
const
  AI_TEXTURE_FLAGS_USEALPHA = $2;
const
  AI_TEXTURE_FLAGS_IGNOREALPHA = $4;

type
  TAiTextureFlags = type TAiEnum32;

const // SourceColor*SourceAlpha + DestColor*(1-SourceAlpha)
  AI_BLENDMODE_DEFAULT  = $0;
  AI_BLENDMODE_ADDITIVE = $1;

type
  TAiBlendMode = type TAiEnum32;

type
  TAiUVTransform = packed record
    mTranslation : TAiVector2D;
    mScaling : TAiVector2D;
    // Rotation angle(radians) in counter-clockwise direction around (0.5,0.5).
    mRotation : TAiFloat;
  end;

const
  AI_PTI_FLOAT   = $1;
  AI_PTI_STRING  = $3;
  AI_PTI_INTEGER = $4;
  AI_PTI_BUFFER  = $5;

type
  TAiPropertyTypeInfo = type TAiEnum32;

type
  PPAiMaterialProperty = ^PAiMaterialProperty;
  PAiMaterialProperty = ^TAiMaterialProperty;

  TAiMaterialProperty = packed record
    mKey : TAiString;
    mSemantic : TAiUInt;
    mIndex : TAiUInt;
    mDataLength : TAiUInt;
    mType : TAiPropertyTypeInfo;
    mData : Pointer;
  end;

type
  PPAiMaterial = ^PAiMaterial;
  PAiMaterial = ^TAiMaterial;

  TAiMaterial = packed record
    mProperties : PPAiMaterialProperty;
    mNumProperties : TAiUInt;
    mNumAllocated : TAiUInt;
  end;

  // ---------------------------------------------------------------------------
  { #define AI_MATKEY_NAME "?mat.name",0,0
   #define AI_MATKEY_TWOSIDED "$mat.twosided",0,0
   #define AI_MATKEY_SHADING_MODEL "$mat.shadingm",0,0
   #define AI_MATKEY_ENABLE_WIREFRAME "$mat.wireframe",0,0
   #define AI_MATKEY_BLEND_FUNC "$mat.blend",0,0
   #define AI_MATKEY_OPACITY "$mat.opacity",0,0
   #define AI_MATKEY_BUMPSCALING "$mat.bumpscaling",0,0
   #define AI_MATKEY_SHININESS "$mat.shininess",0,0
   #define AI_MATKEY_REFLECTIVITY "$mat.reflectivity",0,0
   #define AI_MATKEY_SHININESS_STRENGTH "$mat.shinpercent",0,0
   #define AI_MATKEY_REFRACTI "$mat.refracti",0,0
   #define AI_MATKEY_COLOR_DIFFUSE "$clr.diffuse",0,0
   #define AI_MATKEY_COLOR_AMBIENT "$clr.ambient",0,0
   #define AI_MATKEY_COLOR_SPECULAR "$clr.specular",0,0
   #define AI_MATKEY_COLOR_EMISSIVE "$clr.emissive",0,0
   #define AI_MATKEY_COLOR_TRANSPARENT "$clr.transparent",0,0
   #define AI_MATKEY_COLOR_REFLECTIVE "$clr.reflective",0,0
   #define AI_MATKEY_GLOBAL_BACKGROUND_IMAGE "?bg.global",0,0
  }
  // ---------------------------------------------------------------------------
  // Pure key names for all texture-related properties
const
  _AI_MATKEY_TEXTURE_BASE       = '$tex.file';
  _AI_MATKEY_UVWSRC_BASE        = '$tex.uvwsrc';
  _AI_MATKEY_TEXOP_BASE         = '$tex.op';
  _AI_MATKEY_MAPPING_BASE       = '$tex.mapping';
  _AI_MATKEY_TEXBLEND_BASE      = '$tex.blend';
  _AI_MATKEY_MAPPINGMODE_U_BASE = '$tex.mapmodeu';
  _AI_MATKEY_MAPPINGMODE_V_BASE = '$tex.mapmodev';
  _AI_MATKEY_TEXMAP_AXIS_BASE   = '$tex.mapaxis';
  _AI_MATKEY_UVTRANSFORM_BASE   = '$tex.uvtrafo';
  _AI_MATKEY_TEXFLAGS_BASE      = '$tex.flags';

  // #define AI_MATKEY_TEXTURE(type, N) _AI_MATKEY_TEXTURE_BASE,type,N
  // #define AI_MATKEY_UVWSRC(type, N) _AI_MATKEY_UVWSRC_BASE,type,N
  // #define AI_MATKEY_TEXOP(type, N) _AI_MATKEY_TEXOP_BASE,type,N
  // #define AI_MATKEY_MAPPING(type, N) _AI_MATKEY_MAPPING_BASE,type,N
  // #define AI_MATKEY_TEXBLEND(type, N) _AI_MATKEY_TEXBLEND_BASE,type,N
  // #define AI_MATKEY_MAPPINGMODE_U(type, N) _AI_MATKEY_MAPPINGMODE_U_BASE,type,N
  // #define AI_MATKEY_MAPPINGMODE_V(type, N) _AI_MATKEY_MAPPINGMODE_V_BASE,type,N
  // #define AI_MATKEY_TEXMAP_AXIS(type, N) _AI_MATKEY_TEXMAP_AXIS_BASE,type,N
  // #define AI_MATKEY_UVTRANSFORM(type, N) _AI_MATKEY_UVTRANSFORM_BASE,type,N
  // #define AI_MATKEY_TEXFLAGS(type, N) _AI_MATKEY_TEXFLAGS_BASE,type,N

type
  PAiVectorKey = ^TAiVectorKey;

  TAiVectorKey = record
    mTime : double;
    mValue : TAiVector3D;
  end;

type
  PAiQuatKey = ^TAiQuatKey;

  TAiQuatKey = record
    mTime : double;
    mValue : TAiQuaternion;
  end;

type
  PAiMeshKey = ^TAiMeshKey;

  TAiMeshKey = packed record
    mTime : double;
    { * Index into the aiMesh::mAnimMeshes array of the
     * mesh coresponding to the #aiMeshAnim hosting this
     * key frame. The referenced anim mesh is evaluated
     * according to the rules defined in the docs for #aiAnimMesh.
     * }
    mValue : TAiUInt;
  end;

const
  AI_ANIMATION_BEHAVIOUR_DEFAULT  = $0;
  AI_ANIMATION_BEHAVIOUR_CONSTANT = $1;
  AI_ANIMATION_BEHAVIOUR_LINEAR   = $2;
  AI_ANIMATION_BEHAVIOUR_REPEAT   = $3;

type
  TAiAnimBehaviour = type TAiEnum32;

type
  PPAiNodeAnim = ^PAiNodeAnim;
  PAiNodeAnim = ^TAiNodeAnim;

  TAiNodeAnim = record
    mNodeName : TAiString;
    mNumPositionKeys : TAiUInt;
    mPositionKeys : PAiVectorKey;
    mNumRotationKeys : TAiUInt;
    mRotationKeys : PAiQuatKey;
    mNumScalingKeys : TAiUInt;
    mScalingKeys : PAiVectorKey;
    mPreState : TAiAnimBehaviour;
    mPostState : TAiAnimBehaviour;
  end;

type
  PPAiMeshAnim = ^PAiMeshAnim;
  PAiMeshAnim = ^TAiMeshAnim;

  TAiMeshAnim = packed record
    mName : TAiString;
    mNumKeys : TAiUInt;
    mKeys : PAiMeshKey;
  end;

type
  PPAiAnimation = ^PAiAnimation;
  PAiAnimation = ^TAiAnimation;

  TAiAnimation = record
    mName : TAiString;
    mDuration : double;
    mTicksPerSecond : double;
    mNumChannels : TAiUInt;
    mChannels : PPAiNodeAnim;
    mNumMeshChannels : TAiUInt;
    mMeshChannels : PPAiMeshAnim;
  end;

type
  PAiTexel = ^TAiTexel;

  TAiTexel = packed record
    b, g, r, a : shortint;
  end;

type
  PPAiTexture = ^PAiTexture;
  PAiTexture = ^TAiTexture;

  TAiTexture = packed record
    mWidth : longword;  // if mHeight = 0 mWidth = compressedSize
    mHeight : longword; // if 0 compressed
    achFormatHint : array [0 .. 3] of shortint;
    pcData : PAiTexel;
  end;

const
  AI_LIGHTSOURCE_UNDEFINED   = $0;
  AI_LIGHTSOURCE_DIRECTIONAL = $1;
  AI_LIGHTSOURCE_POINT       = $2;
  AI_LIGHTSOURCE_SPOT        = $3;

type
  TAiLightSourceType = type TAiEnum32;

type
  PPAiLight = ^PAiLight;
  PAiLight = ^TAiLight;

  TAiLight = packed record
    mName : TAiString;
    mType : TAiLightSourceType;
    mPosition : TAiVector3D;
    mDirection : TAiVector3D;
    mAttenuationConstant : TAiFloat;
    mAttenuationLinear : TAiFloat;
    mAttenuationQuadratic : TAiFloat;
    mColorDiffuse : TAiColor3D;
    mColorSpecular : TAiColor3D;
    mColorAmbient : TAiColor3D;
    mAngleInnerCone : TAiFloat;
    mAngleOuterCone : TAiFloat;
  end;

type
  PPAiCamera = ^PAiCamera;
  PAiCamera = ^TAiCamera;

  TAiCamera = packed record
    mName : TAiString;
    mPosition : TAiVector3D;
    mUp : TAiVector3D;
    mLookAt : TAiVector3D;
    mHorizontalFOV : TAiFloat;
    mClipPlaneNear : TAiFloat;
    mClipPlaneFar : TAiFloat;
    mAspect : TAiFloat;
  end;

type
  PPAiNode = ^PAiNode;
  PAiNode = ^TAiNode;

  TAiNode = packed record
    mName : TAiString;
    /// <summary> The transformation relative to the node's parent.</summary>
    mTransformation : TAiMatrix4x4;
    /// <summary> Parent node. NULL if this node is the root node.</summary>
    mParent : PAiNode;
    /// <summary> The number of child nodes of this node.</summary>
    mNumChildren : TAiUInt;
    /// <summary> The child nodes of this node. NULL if mNumChildren is 0.</summary>
    mChildren : PPAiNode;
    /// <summary> The number of meshes of this node.</summary>
    mNumMeshes : TAiUInt;
    /// <summary> The meshes of this node. Each entry is an index into the mesh.</summary>
    mMeshes : PAiUInt;
    /// <summary> Metadata associated with this node or NULL if there is no metadata.
    /// Whether any metadata is generated depends on the source file format. See the
    /// @link importer_notes @endlink page for more information on every source file
    /// format. Importers that don't document any metadata don't write any. </summary>
    mMetaData : PAiMetaData;
  end;

const
  AI_SCENE_FLAGS_INCOMPLETE         = $1;
  AI_SCENE_FLAGS_VALIDATED          = $2;
  AI_SCENE_FLAGS_VALIDATION_WARNING = $4;
  AI_SCENE_FLAGS_NON_VERBOSE_FORMAT = $8;
  AI_SCENE_FLAGS_TERRAIN            = $10;

type
  TAiSceneFlags = type TAiUInt;

type
  PAiScene = ^TAiScene;

  TAiScene = packed record
    /// <summary> Any combination of the AI_SCENE_FLAGS_XXX flags. By default
    /// this value is 0, no flags are set. Most applications will
    /// want to reject all scenes with the AI_SCENE_FLAGS_INCOMPLETE
    /// bit set.</summary>
    mFlags : TAiSceneFlags;
    mRootNode : PAiNode;
    mNumMeshes : TAiUInt;
    mMeshes : PPAiMesh;
    mNumMaterials : TAiUInt;
    mMaterials : PPAiMaterial;
    mNumAnimations : TAiUInt;
    mAnimations : PPAiAnimation;
    mNumTextures : TAiUInt;
    mTextures : PPAiTexture;
    mNumLights : TAiUInt;
    mLights : PPAiLight;
    mNumCameras : longword;
    mCameras : PPAiCamera;
  end;

const
  AI_POSTPROCESS_CALCTANGENTSPACE         = $1;
  AI_POSTPROCESS_JOINIDENTICALVERTICES    = $2;
  AI_POSTPROCESS_MAKELEFTHANDED           = $4;
  AI_POSTPROCESS_TRIANGULATE              = $8;
  AI_POSTPROCESS_REMOVECOMPONENT          = $10;
  AI_POSTPROCESS_GENNORMALS               = $20;
  AI_POSTPROCESS_GENSMOOTHNORMALS         = $40;
  AI_POSTPROCESS_SPLITLARGEMESHES         = $80;
  AI_POSTPROCESS_PRETRANSFORMVERTICES     = $100;
  AI_POSTPROCESS_LIMITBONEWEIGHTS         = $200;
  AI_POSTPROCESS_VALIDATEDATASTRUCTURE    = $400;
  AI_POSTPROCESS_IMPROVECACHELOCALITY     = $800;
  AI_POSTPROCESS_REMOVEREDUNDANTMATERIALS = $1000;
  AI_POSTPROCESS_FIXINFACINGNORMALS       = $2000;
  AI_POSTPROCESS_SORTBYPTYPE              = $8000;
  AI_POSTPROCESS_FINDDEGENERATES          = $10000;
  AI_POSTPROCESS_FINDINVALIDDATA          = $20000;
  AI_POSTPROCESS_GENUVCOORDS              = $40000;
  AI_POSTPROCESS_TRANSFORMUVCOORDS        = $80000;
  AI_POSTPROCESS_FINDINSTANCES            = $100000;
  AI_POSTPROCESS_OPTIMIZEMESHES           = $200000;
  AI_POSTPROCESS_OPTIMIZEGRAPH            = $400000;
  AI_POSTPROCESS_FLIPUVS                  = $800000;
  AI_POSTPROCESS_FLIPWINDINGORDER         = $1000000;

  AI_POSTPROCESS_PRESET_REALTIME_SPEED =
    0 or
    AI_POSTPROCESS_CALCTANGENTSPACE or
    AI_POSTPROCESS_GENNORMALS or
    AI_POSTPROCESS_JOINIDENTICALVERTICES or
    AI_POSTPROCESS_TRIANGULATE or
    AI_POSTPROCESS_GENUVCOORDS or
    AI_POSTPROCESS_SORTBYPTYPE;

  AI_POSTPROCESS_PRESET_REALTIME_QUALITY =
    0 or
    AI_POSTPROCESS_CALCTANGENTSPACE or
    AI_POSTPROCESS_GENSMOOTHNORMALS or
    AI_POSTPROCESS_JOINIDENTICALVERTICES or
    AI_POSTPROCESS_IMPROVECACHELOCALITY or
    AI_POSTPROCESS_LIMITBONEWEIGHTS or
    AI_POSTPROCESS_REMOVEREDUNDANTMATERIALS or
    AI_POSTPROCESS_SPLITLARGEMESHES or
    AI_POSTPROCESS_TRIANGULATE or
    AI_POSTPROCESS_GENUVCOORDS or
    AI_POSTPROCESS_SORTBYPTYPE or
    AI_POSTPROCESS_FINDDEGENERATES or
    AI_POSTPROCESS_FINDINVALIDDATA;

  AI_POSTPROCESS_PRESET_REALTIME_MAXQUALITY =
    AI_POSTPROCESS_PRESET_REALTIME_QUALITY or
    AI_POSTPROCESS_FINDINSTANCES or
    AI_POSTPROCESS_VALIDATEDATASTRUCTURE or
    AI_POSTPROCESS_OPTIMIZEMESHES;

type
  TAiPostProcessSteps = type TAiEnum32;

type
  TAiUserData = type Pointer;

type
  PAiFile = ^TAiFile;

  // aiFile callbacks
  TAiFileReadProc = function(aFile : PAiFile; data : Pointer; size, count : TAiSize_t) : TAiSize_t; cdecl;
  TAIFileWriteProc = function(aFile : PAiFile; data : Pointer; size, count : TAiSize_t) : TAiSize_t; cdecl;
  TAiFileTellProc = function(aFile : PAiFile) : TAiSize_t; cdecl;
  TAiFileSizeProc = function(aFile : PAiFile) : TAiSize_t; cdecl;
  TAiFileFlushProc = procedure(aFile : PAiFile); cdecl;
  TAiFileSeekProc = function(aFile : PAiFile; count : TAiSize_t; origin : TAiOrigin) : TAiReturn; cdecl;

  TAiFile = packed record
    fileReadProc : TAiFileReadProc;
    fileWriteProc : TAIFileWriteProc;
    fileTellProc : TAiFileTellProc;
    fileSizeProc : TAiFileSizeProc;
    fileSeek : TAiFileSeekProc;
    fileFlushProc : TAiFileFlushProc;
    userData : TAiUserData;
  end;

type
  PAiFileIO = ^TAiFileIO;
  // aiFileIO callbacks
  TAiFileOpenProc = function(aFileIO : PAiFileIO; filename, mode : PChar) : PAiFile; cdecl;
  TAiFileCloseProc = procedure(aFileIO : PAiFileIO; aFile : PAiFile); cdecl;

  TAiFileIO = packed record
    fileOpenProc : TAiFileOpenProc;
    fileCloseProc : TAiFileCloseProc;
    userData : TAiUserData;
  end;

type
  TAiLogStreamCallback = procedure(message, user : PAiChar); cdecl;

type
  PAiLogStream = ^TAiLogStream;

  TAiLogStream = record
    callback : TAiLogStreamCallback;
    user : Pointer;
  end;

type
  PAiMemoryInfo = ^TAiMemoryInfo;

  TAiMemoryInfo = record
    textures : longword;
    materials : longword;
    meshes : longword;
    nodes : longword;
    animations : longword;
    cameras : longword;
    lights : longword;
    total : longword;
  end;

const
  ASSIMP_CFLAGS_SHARED         = $1;
  ASSIMP_CFLAGS_STLPORT        = $2;
  ASSIMP_CFLAGS_DEBUG          = $4;
  ASSIMP_CFLAGS_NOBOOST        = $8;
  ASSIMP_CFLAGS_SINGLETHREADED = $10;

  /// ============================== config constants ==========================

  /// <summary> Enables time measurements.
  /// If enabled, measures the time needed for each part of the loading
  /// process (i.e. IO time, importing, postprocessing, ..) and dumps
  /// these timings to the DefaultLogger. See the @link perf Performance
  /// Page@endlink for more information on this topic.
  /// Property type: bool. Default value: false.</summary>
  AI_CONFIG_GLOB_MEASURE_TIME : AnsiString = 'GLOB_MEASURE_TIME';
  /// <summary> Set whether the fbx importer will merge all geometry layers present
  /// in the source file or take only the first.
  /// The default value is true (1)
  /// Property type: bool</summary>
  AI_CONFIG_IMPORT_FBX_READ_ALL_GEOMETRY_LAYERS : AnsiString = 'IMPORT_FBX_READ_ALL_GEOMETRY_LAYERS';
  /// <summary> Set whether the fbx importer will read all materials present in the
  /// source file or take only the referenced materials.
  /// This is void unless IMPORT_FBX_READ_MATERIALS=1.
  /// The default value is false (0)
  /// Property type: bool</summary>
  AI_CONFIG_IMPORT_FBX_READ_ALL_MATERIALS : AnsiString = 'IMPORT_FBX_READ_ALL_MATERIALS';
  /// <summary> Set whether the fbx importer will read materials.
  /// The default value is true (1)
  /// Property type: bool</summary>
  AI_CONFIG_IMPORT_FBX_READ_MATERIALS : AnsiString = 'IMPORT_FBX_READ_MATERIALS';
  /// <summary> Set whether the fbx importer will read cameras.
  /// The default value is true (1)
  /// Property type: bool</summary>
  AI_CONFIG_IMPORT_FBX_READ_CAMERAS : AnsiString = 'IMPORT_FBX_READ_CAMERAS';
  /// <summary> Set whether the fbx importer will read animations.
  /// The default value is true (1)
  /// Property type: bool</summary>
  AI_CONFIG_IMPORT_FBX_READ_ANIMATIONS : AnsiString = 'IMPORT_FBX_READ_ANIMATIONS';
  /// <summary> Set whether the fbx importer will act in strict mode in which only
  /// FBX 2013 is supported and any other sub formats are rejected. FBX 2013
  /// is the primary target for the importer, so this format is best
  /// supported and well-tested.
  /// The default value is false (0)
  /// Property type: bool</summary>
  AI_CONFIG_IMPORT_FBX_STRICT_MODE : AnsiString = 'IMPORT_FBX_STRICT_MODE';
  /// <summary> Set whether the fbx importer will preserve pivot points for
  /// transformations (as extra nodes). If set to false, pivots and offsets
  /// will be evaluated whenever possible.
  /// The default value is true (1)
  /// Property type: bool</summary>
  AI_CONFIG_IMPORT_FBX_PRESERVE_PIVOTS : AnsiString = 'IMPORT_FBX_PRESERVE_PIVOTS';

type
  PAiPropertyStore = ^TAiPropertyStore;

  TAiPropertyStore = record
    Sentinel : TAiChar;
  end;

type
  TAiCompileFlags = type TAiUInt;

type // aiBase
  TAiGetErrorString = function : PAiChar; cdecl;

  TAiGetLegalString = function : PAiChar; cdecl;
  TAiGetVersionMinor = function : TAiUInt; cdecl;
  TAiGetVersionMajor = function : TAiUInt; cdecl;
  TAiGetVersionRevision = function : TAiUInt; cdecl;
  TAiGetCompileFlags = function : TAiCompileFlags; cdecl;

  // aiImport
  TAiImportFile = function(pFile : PAiChar; pFlags : TAiPostProcessSteps) : PAiScene; cdecl;
  TAiImportFileEx = function(pFile : PAiChar; pFlags : TAiPostProcessSteps; const pFS : TAiFileIO) : PAiScene; cdecl;
  TAiImportFileFromMemory = function(pBuffer : Pointer; pLength : TAiUInt; pFlags : TAiPostProcessSteps; pHint : PAiChar) : PAiScene; cdecl;
  TAiImportFileFromMemoryWithProperties = function(pBuffer : Pointer; pLength : TAiUInt; pFlags : TAiPostProcessSteps; pHint : PAiChar; pProps : PAiPropertyStore) : PAiScene; cdecl;
  TAiApplyPostProcessing = function(const pScene : TAiScene; pFlags : TAiPostProcessSteps) : PAiScene; cdecl;
  TAiReleaseImport = procedure(const pScene : TAiScene); cdecl;
  TAiIsExtensionSupported = function(szExtension : PAiChar) : TAiBool; cdecl;
  TAiGetExtensionList = procedure(out szOut : TAiString); cdecl;
  TAiGetMemoryRequirements = procedure(pIn : PAiScene; _in : PAiMemoryInfo); cdecl;
  TAiCreatePropertyStore = function : PAiPropertyStore; cdecl;
  TAiReleasePropertyStore = procedure(p : PAiPropertyStore); cdecl;
  TAiSetImportPropertyInteger = procedure(store : PAiPropertyStore; szName : PAiChar; Value : TAiInt); cdecl;
  TAiSetImportPropertyFloat = procedure(store : PAiPropertyStore; szName : PAiChar; Value : TAiFloat); cdecl;
  TAiSetImportPropertyString = procedure(store : PAiPropertyStore; szName : PAiChar; Value : PAiString); cdecl;

  // aiLogging
  TAiGetPredefinedLogStream = function(pStreams : TAiDefaultLogStream; _file : PAiChar) : TAiLogStream; cdecl;
  TAiAttachLogStream = procedure(stream : PAiLogStream); cdecl;
  TAiEnableVerboseLogging = procedure(d : TAiBool); cdecl;
  TAiDetachLogStream = function(stream : PAiLogStream) : TAiReturn; cdecl;
  TAiDetachAllLogStreams = procedure; cdecl;

  // aiMaterial
  TAiGetMaterialProperty = function(pMat : PAiMaterial; pKey : PAiChar; _type, index : TAiUInt; pPropOut : PPAiMaterialProperty) : TAiReturn; cdecl;
  TAiGetMaterialFloatArray = function(pMat : PAiMaterial; pKey : PAiChar; _type, index : TAiUInt; out pOut : TAiFloat; pMax : PAiUInt) : TAiReturn; cdecl;
  TAiGetMaterialIntegerArray = function(pMat : PAiMaterial; pKey : PAiChar; _type, index : TAiUInt; out pOut : TAiInt; pMax : PAiUInt) : TAiReturn; cdecl;
  TAiGetMaterialColor = function(pMat : PAiMaterial; pKey : PAiChar; _type, index : TAiUInt; out pOut : TAiColor4D) : TAiReturn; cdecl;
  TAiGetMaterialString = function(pMat : PAiMaterial; pKey : PAiChar; _type, index : TAiUInt; out pOut : TAiString) : TAiReturn; cdecl;
  TAiGetMaterialTextureCount = function(pMat : PAiMaterial; _type : TAiTextureType) : TAiUInt; cdecl;
  TAiGetMaterialTexture = function(pMat : PAiMaterial; _type : TAiTextureType; index : TAiUInt; path : PAiString; mapping : PAiTextureMapping; uvindex : PAiUInt; blend : PAiFloat; op : PAiTextureOp; mapmode : PAiTextureMapMode; flags : PAiUInt) : TAiReturn; cdecl;

  // aiMath
  TAiCreateQuaternionFromMatrix = procedure(out quat : TAiQuaternion; const mat : TAiMatrix3x3);
  TAiDecomposeMatrix = procedure(const mat : TAiMatrix4x4; out scaling : TAiVector3D; out rotation : TAiQuaternion; out position : TAiVector3D);
  TAiTransposeMatrix4 = procedure(var mat : TAiMatrix4x4);
  TAiTransposeMatrix3 = procedure(var mat : TAiMatrix3x3);
  TAiTransformVecByMatrix3 = procedure(var vec : TAiVector3D; const mat : TAiMatrix3x3);
  TAiTransformVecByMatrix4 = procedure(var vec : TAiVector3D; const mat : TAiMatrix4x4);
  TAiMultiplyMatrix3 = procedure(var dst : TAiMatrix3x3; const src : TAiMatrix3x3);
  TAiMultiplyMatrix4 = procedure(var dst : TAiMatrix4x4; const src : TAiMatrix4x4);
  TAiIdentityMatrix3 = procedure(out mat : PAiMatrix3x3);
  TAiIdentityMatrix4 = procedure(out mat : PAiMatrix4x4);

var // aiBase
  aiGetErrorString : TAiGetErrorString;
  aiGetLegalString : TAiGetLegalString;
  aiGetVersionMinor : TAiGetVersionMinor;
  aiGetVersionMajor : TAiGetVersionMajor;
  aiGetVersionRevision : TAiGetVersionRevision;
  aiGetCompileFlags : TAiGetCompileFlags;

  // aiImport
  aiImportFile : TAiImportFile;
  aiImportFileEx : TAiImportFileEx;
  aiImportFileFromMemory : TAiImportFileFromMemory;
  aiImportFileFromMemoryWithProperties : TAiImportFileFromMemoryWithProperties;
  aiApplyPostProcessing : TAiApplyPostProcessing;
  aiReleaseImport : TAiReleaseImport;
  aiIsExtensionSupported : TAiIsExtensionSupported;
  aiGetExtensionList : TAiGetExtensionList;
  aiGetMemoryRequirements : TAiGetMemoryRequirements;

  aiCreatePropertyStore : TAiCreatePropertyStore;
  aiReleasePropertyStore : TAiReleasePropertyStore;
  aiSetImportPropertyInteger : TAiSetImportPropertyInteger;
  aiSetImportPropertyFloat : TAiSetImportPropertyFloat;
  aiSetImportPropertyString : TAiSetImportPropertyString;

  // aiLogging
  aiGetPredefinedLogStream : TAiGetPredefinedLogStream;
  aiAttachLogStream : TAiAttachLogStream;
  aiEnableVerboseLogging : TAiEnableVerboseLogging;
  aiDetachLogStream : TAiDetachLogStream;
  aiDetachAllLogStreams : TAiDetachAllLogStreams;

  // aiMaterial
  aiGetMaterialProperty : TAiGetMaterialProperty;
  aiGetMaterialFloatArray : TAiGetMaterialFloatArray;
  aiGetMaterialIntegerArray : TAiGetMaterialIntegerArray;
  aiGetMaterialColor : TAiGetMaterialColor;
  aiGetMaterialString : TAiGetMaterialString;
  aiGetMaterialTextureCount : TAiGetMaterialTextureCount;
  aiGetMaterialTexture : TAiGetMaterialTexture;

  // aiMath
  aiCreateQuaternionFromMatrix : TAiCreateQuaternionFromMatrix;
  aiTransposeMatrix4 : TAiTransposeMatrix4;
  aiTransposeMatrix3 : TAiTransposeMatrix3;
  aiTransformVecByMatrix3 : TAiTransformVecByMatrix3;
  aiTransformVecByMatrix4 : TAiTransformVecByMatrix4;
  aiMultiplyMatrix3 : TAiMultiplyMatrix3;
  aiMultiplyMatrix4 : TAiMultiplyMatrix4;
  aiIdentityMatrix3 : TAiIdentityMatrix3;
  aiIdentityMatrix4 : TAiIdentityMatrix4;

procedure initAssimp();
procedure releaseAssimp;

implementation

var
  assimpLibHandle : HMODULE = 0;

procedure readAiBase; {$IFDEF INLINE}inline; {$ENDIF INLINE}
begin
  aiGetErrorString := GetProcAddress(assimpLibHandle, 'aiGetErrorString');
  aiGetLegalString := GetProcAddress(assimpLibHandle, 'aiGetLegalString');
  aiGetVersionMinor := GetProcAddress(assimpLibHandle, 'aiGetVersionMinor');
  aiGetVersionMajor := GetProcAddress(assimpLibHandle, 'aiGetVersionMajor');
  aiGetVersionRevision := GetProcAddress(assimpLibHandle, 'aiGetVersionRevision');
  aiGetCompileFlags := GetProcAddress(assimpLibHandle, 'aiGetCompileFlags');
end;

procedure readAiImport; // {$IFDEF INLINE}inline; {$ENDIF INLINE}
begin
  aiImportFile := GetProcAddress(assimpLibHandle, 'aiImportFile');
  aiImportFileEx := GetProcAddress(assimpLibHandle, 'aiImportFileEx');
  aiImportFileFromMemory := GetProcAddress(assimpLibHandle, 'aiImportFileFromMemory');
  aiImportFileFromMemoryWithProperties := GetProcAddress(assimpLibHandle, 'aiImportFileFromMemoryWithProperties');
  aiApplyPostProcessing := GetProcAddress(assimpLibHandle, 'aiApplyPostProcessing');
  aiReleaseImport := GetProcAddress(assimpLibHandle, 'aiIsExtensionSupported');
  aiIsExtensionSupported := GetProcAddress(assimpLibHandle, 'aiIsExtensionSupported');
  aiGetExtensionList := GetProcAddress(assimpLibHandle, 'aiGetExtensionList');
  aiGetMemoryRequirements := GetProcAddress(assimpLibHandle, 'aiGetMemoryRequirements');
  aiCreatePropertyStore := GetProcAddress(assimpLibHandle, 'aiCreatePropertyStore');
  aiReleasePropertyStore := GetProcAddress(assimpLibHandle, 'aiReleasePropertyStore');
  aiSetImportPropertyInteger := GetProcAddress(assimpLibHandle, 'aiSetImportPropertyInteger');
  aiSetImportPropertyFloat := GetProcAddress(assimpLibHandle, 'aiSetImportPropertyFloat');
  aiSetImportPropertyString := GetProcAddress(assimpLibHandle, 'aiSetImportPropertyString');
end;

procedure readAiLogging; {$IFDEF INLINE}inline; {$ENDIF INLINE}
begin
  aiGetPredefinedLogStream := GetProcAddress(assimpLibHandle, 'aiGetPredefinedLogStream');
  aiAttachLogStream := GetProcAddress(assimpLibHandle, 'aiAttachLogStream');
  aiEnableVerboseLogging := GetProcAddress(assimpLibHandle, 'aiEnableVerboseLogging');
  aiDetachLogStream := GetProcAddress(assimpLibHandle, 'aiDetachLogStream');
  aiDetachAllLogStreams := GetProcAddress(assimpLibHandle, 'aiDetachAllLogStreams');
end;

procedure readAiMaterial; {$IFDEF INLINE}inline; {$ENDIF INLINE}
begin
  aiGetMaterialProperty := GetProcAddress(assimpLibHandle, 'aiGetMaterialProperty');
  aiGetMaterialFloatArray := GetProcAddress(assimpLibHandle, 'aiGetMaterialFloatArray');
  aiGetMaterialIntegerArray := GetProcAddress(assimpLibHandle, 'aiGetMaterialIntegerArray');
  aiGetMaterialColor := GetProcAddress(assimpLibHandle, 'aiGetMaterialColor');
  aiGetMaterialString := GetProcAddress(assimpLibHandle, 'aiGetMaterialString');
  aiGetMaterialTextureCount := GetProcAddress(assimpLibHandle, 'aiGetMaterialTextureCount');
  aiGetMaterialTexture := GetProcAddress(assimpLibHandle, 'aiGetMaterialTexture');
end;

procedure readAiMath; {$IFDEF INLINE}inline; {$ENDIF INLINE}
begin
  aiCreateQuaternionFromMatrix := GetProcAddress(assimpLibHandle, 'aiCreateQuaternionFromMatrix');
  aiTransposeMatrix4 := GetProcAddress(assimpLibHandle, 'aiTransposeMatrix4');
  aiTransposeMatrix3 := GetProcAddress(assimpLibHandle, 'aiTransposeMatrix3');
  aiTransformVecByMatrix3 := GetProcAddress(assimpLibHandle, 'aiTransformVecByMatrix3');
  aiTransformVecByMatrix4 := GetProcAddress(assimpLibHandle, 'aiTransformVecByMatrix4');
  aiMultiplyMatrix3 := GetProcAddress(assimpLibHandle, 'aiMultiplyMatrix3');
  aiMultiplyMatrix4 := GetProcAddress(assimpLibHandle, 'aiMultiplyMatrix4');
  aiIdentityMatrix3 := GetProcAddress(assimpLibHandle, 'aiIdentityMatrix3');
  aiIdentityMatrix4 := GetProcAddress(assimpLibHandle, 'aiIdentityMatrix4');
end;

procedure readProcedureAdresses; {$IFDEF INLINE}inline; {$ENDIF INLINE}
begin
  readAiBase;
  readAiImport;
  readAiLogging;
  readAiMaterial;
  readAiMath;
end;

procedure initAssimp();
begin
  // no need to double load libary
  // if assimpLibHandle <> 0 then FreeLibrary(assimpLibHandle);
  if assimpLibHandle = 0 then
  begin
    assimpLibHandle := LoadLibrary(PChar(FormatDateiPfad(ASSIMP_LIBNAME)));
    // if loading first libary failed, try alternative
    if assimpLibHandle = 0 then
        assimpLibHandle := LoadLibrary(PChar(FormatDateiPfad(ASSIMP_LIBNAME_ALTERNATIVE)));

    if assimpLibHandle <> 0 then
    begin
      readProcedureAdresses;
    end
    // handle = 0, an error occured
    else
        RaiseLastOSError;
  end;
end;

procedure releaseAssimp;
begin
  if assimpLibHandle <> 0 then FreeLibrary(assimpLibHandle);
end;

{ TAiString }

function TAiString.AsString : string;
var
  i : integer;
begin
  setlength(result, self.length);
  // copy and convert ansichar data to string
  for i := 0 to self.length - 1 do
      result[i + 1] := Char(self.data[i]);
end;

{ TAiFace }

function TAiFace.asArray : TArray<TAiUInt>;
begin
  setlength(result, self.mNumIndices);
  move(self.mIndices^, result[0], self.mNumIndices * SizeOf(TAiUInt));
end;

{ TAiVector3D }

class operator TAiVector3D.implicit(a : TAiVector3D) : RVector3;
begin
  result := RVector3.Create(a.x, a.y, a.z);
end;

{ TAiVector2D }

class operator TAiVector2D.implicit(a : TAiVector2D) : RVector2;
begin
  result := RVector2.Create(a.x, a.y);
end;

{ TAiMatrix4x4 }

class operator TAiMatrix4x4.implicit(a : TAiMatrix4x4) : RMatrix;
begin
  result := RMatrix.Create([
    a.a1, a.a2, a.a3, a.a4,
    a.b1, a.b2, a.b3, a.b4,
    a.c1, a.c2, a.c3, a.c4,
    a.d1, a.d2, a.d3, a.d4
    ]);
end;

{ TAiQuaternion }

class operator TAiQuaternion.implicit(a : TAiQuaternion) : RQuaternion;

begin
  result := RQuaternion.Create(a.x, a.y, a.z, a.w);
end;

end.
