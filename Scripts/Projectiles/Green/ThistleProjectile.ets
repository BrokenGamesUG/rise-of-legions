{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
{$IFDEF CLIENT}
var Color : integer;
{$ENDIF}
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    if Entity.SkinID = SKIN_GROUP_UNDERWORLD then
      Color := $80F0F8FF
    else if Entity.SkinID = SKIN_GROUP_SCILL then
      Color := $80ffff00
    else
      Color := $8073ff00;
    TVertexQuadComponent.Create(Entity, 'Units\Green\Thistle' + Entity.SkinFileSuffix + '\Projectile\thistle_projectile.tga', 1.0, 0.25)
      .Color(Color)
      .CameraOriented()
      .Additive();

    if Entity.SkinID = SKIN_GROUP_UNDERWORLD then
      Color := $10F0F8FF
    else if Entity.SkinID = SKIN_GROUP_SCILL then
      Color := $10ffff00
    else
      Color := $1073ff00;
    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\Trace.tga')
      .Color(Color)
      .Width(0.15)
      .SamplingDistance(0.5)
      .FadeLength(2.0)
      .MaxLength(14.0)
      .TexturePerDistance(4.0)
      .Additive;
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0]);
    // projectile damage
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 16, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);
    TOrienterFrontInverterComponent.Create(Entity);

    TSoundComponent.Create(Entity, 'event:/card/green/unit/thistle/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
