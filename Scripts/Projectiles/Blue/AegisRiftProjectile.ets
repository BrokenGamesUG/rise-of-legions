{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 60 / 1000);
  Entity.Blackboard.SetValue(eiDamageType, [0], [dtTrue]);
end;

procedure CreateMeta(Entity : TEntity);
var Color : integer;
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Units\Blue\Aegis' + Entity.SkinFileSuffix + '\Projectile\AegisProjectile.png', 5.0, 0.85)
      .CameraOriented()
      .Additive();

    TVertexQuadComponent.Create(Entity, 'Effects\Textures\BlueLensFlare' + Entity.SkinFileSuffix + '.tga', 9.0, 9.0)
      .ScreenSpace()
      .Additive();

    if Entity.SkinID = SKIN_GROUP_STEAM then
      Color := $A07eca8b
    else
      Color := $A05BA9FF;

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\BlueTrace.tga')
      .Color(Color)
      .Width(0.85)
      .SamplingDistance(0.5)
      .FadeLength(5.0)
      .MaxLength(6.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.1)
      .Additive;

    if Entity.SkinID = SKIN_GROUP_STEAM then
      Color := $807eca8b
    else
      Color := $804FA6FF;

    TPointLightComponent.Create(Entity, Color, 0)
      .SetLightShape(RVector3.Create(3, 2, 0));
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .NoTargetChecks();
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyKillComponent.CreateGrouped(Entity, [0])
      .Exile;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('InstaKill')
      .TriggerOnKillDone;
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(0, 0, 0)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [1]);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\aegis' + Entity.SkinFileSuffix + '_projectile_impact.pfx', 1.0)
      .ActivateOnFireWarhead();

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/blue/unit/aegis/attack_impact')
      .TriggerOnFireWarhead;
    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/shared/effect/annihilate')
      .TriggerOnFireWarhead;
  {$ENDIF}
end;
