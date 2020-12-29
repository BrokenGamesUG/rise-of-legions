{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
{$IFDEF CLIENT}
var TraceFile : string;
    Color : integer;
{$ENDIF}
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TMeshComponent.Create(Entity, 'Units\White\Archer' + Entity.SkinFileSuffix + '\Arrow\Arrow.xml')
      .ApplyAutoSizeNormalization;
    Entity.Eventbus.Write(eiModelSize, [1.2]);

    if Entity.SkinID = SKIN_GROUP_ROFL then
       TraceFile := 'CrystalTrace.tga'
    else
       TraceFile := 'LightTrace.tga';

    if Entity.SkinID = SKIN_GROUP_INFLAMED then
      Color := $FFb83226
    else
      Color := $80FFFFFF;

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\' + TraceFile)
      .Color(Color)
      .Width(0.15)
      .SamplingDistance(0.5)
      .FadeLength(3.0)
      .MaxLength(7.0)
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
    TOrienterFrontInverterComponent.Create(Entity);

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/white/unit/archer/attack_impact')
      .CheckGroup([1])
      .TriggerOnFireWarhead;

    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustNotHave([upUnit]);

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/white/unit/archer/attack_impact_unit')
      .CheckGroup([2])
      .TriggerOnFireWarhead;

    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [2])
      .MustHave([upUnit]);
  {$ENDIF}
end;
