{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Units\Black\VoidBowman' + Entity.SkinFileSuffix + '\VoidBowmanArrow.tga', 1.6, 0.4)
      .CameraOriented();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Units\Black\VoidBowman' + Entity.SkinFileSuffix + '\VoidBowmanArrowTrace.tga')
      .Color($80FFFFFF)
      .Width(0.25)
      .SamplingDistance(0.5)
      .FadeLength(5.0)
      .MaxLength(5.0)
      .TexturePerDistance(4.0);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 16, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/black/unit/voidbowman/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
