{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 14 / 1000);
  Entity.Blackboard.SetValue(eiWelaDamage, [1], 1.0);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\GreenLensFlare.tga', 1.8, 0.9)
      .ScreenSpace()
      .Additive()
      .Color($A0FFFFFF);

    TPointLightComponent.Create(Entity, $FF80E92B, 2);
    TParticleEffectComponent.Create(Entity, '\Green\sapling_projectile.pfx', 4.0)
      .ActivateOnCreate();
    TParticleEffectComponent.CreateGrouped(Entity, [], '\Green\oracle_boost.pfx', 1.0)
      .ActivateOnFree();
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
var color : integer;
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0, 1]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0, 1]);
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [0])
      .SetResourceType(reHealth)
      .ChangesMax();
    TWarheadSpottyResourceComponent.CreateGrouped(Entity, [1])
      .SetResourceType(reWelaCharge);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 16, 0, 1);

    if Entity.SkinID = SKIN_GROUP_UNDERWORLD then
      color := $40ccff00
    else if Entity.SkinID = SKIN_GROUP_CRUSADER then
      color := $40feff98
    else
      color := $4073ff00;

    TMeshEffectComponent.CreateGrouped(Entity, [0])
      .TargetGroup([])
      .ActivateOnFire
      .ApplyToFireTarget
      .SetEffect(
        TMeshEffectSoulGain.Create(400)
          .Color(color)
          .AddKey(0, 0.0)
          .AddKey(400, 1.0)
          .Additive
      );

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/unit/oracle/sapling_boost/attack_fire')
      .TriggerOnCreate();

    TSoundComponent.CreateGrouped(Entity, [], 'event:/card/green/unit/oracle/sapling_boost/attack_impact')
      .TriggerOnFree();
  {$ENDIF}
end;
