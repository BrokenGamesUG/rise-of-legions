{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);

  // anti-air
  Entity.Blackboard.SetValue(eiWelaModifier, [1], 2.0); // 200% against flying
end;

procedure CreateMeta(Entity : TEntity);
var Color : integer;
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    if Entity.SkinID = SKIN_GROUP_STEAM then
      Color := $5A7eca8b
    else
      Color := $5A4fa6ff;

    TPointLightComponent.Create(Entity, Color, 3);

    if Entity.SkinID = SKIN_GROUP_STEAM then
      Color := $FF7eca8b
    else
      Color := $FF4fa6ff;

    TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 14.0, 7.0)
      .ScreenSpace()
      .Additive()
      .Color(Color)
      .SetModelOffset(RVector3.Create(0,0,-2.4));
    Entity.Eventbus.Write(eiModelSize, [0.2]);

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\Trace.tga')
      .Color(Color)
      .Width(0.35)
      .SamplingDistance(0.5)
      .FadeLength(2.0)
      .MaxLength(3.0)
      .TexturePerDistance(4.0)
      .FadeWidening(-0.1)
      .Additive;

    if Entity.SkinID = SKIN_GROUP_STEAM then
      Color := $FF587d6d
    else
      Color := $FF6d8ba1;

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\SmokeTrace.tga')
      .Color(Color)
      .Width(0.35)
      .SamplingDistance(0.5)
      .FadeLength(10.0)
      .MaxLength(15.0)
      .TexturePerDistance(4.0)
      .FadeWidening(0.55);

    TParticleEffectComponent.Create(Entity, '\Blue\missile' + Entity.SkinFileSuffix + '_trail.pfx', 0.15)
      .ActivateOnCreate();
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [])
      .Name('Missile')
      .TriggerOnCreate;

    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .NoTargetChecks();
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [0], eiDamageable);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustNotHave([upBanished]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSplashDamageComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Splash')
      .TriggerOnKillDone;
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('AntiAir')
      .TriggerOnDamageDone
      .CheckUnitPropertyMustHaveAny([upFlying, upMonumental]);

    TModifierMultiplyDealtDamageComponent.CreateGrouped(Entity, [0])
      .MustNotHave([dtSpell])
      .CheckWelaConstraint
      .SetValueGroup([1]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHaveAny([upFlying, upMonumental]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerRotationComponent.CreateGrouped(Entity, [])
      .Radius(0.5)
      .RotationSpeed(0, 0, 3 * PI)
      .Phase(random)
      .FadeIn(200);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\missile' + Entity.SkinFileSuffix + '_impact.pfx', 2.25)
      .ActivateOnFireWarhead()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOrientationDefault;

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\blue_border_wide_once.pfx', 5.0)
      .ActivateOnFire()
      .FixedOrientationDefault()
      .ScaleWith(eiWelaAreaOfEffect)
      .FixedOffsetGround
      .VisibleWithOption(coGameplayShowEffectRadius);

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationLight
      .ActivateOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorLight
      .ActivateOnFree;
  {$ENDIF}
end;
