{$INCLUDE 'DropTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitDropData(Entity, True, {@UBL_Tier}3);
  Entity.Blackboard.SetIndexedValue(eiResourceCost, [], reGold, GetCardBaseCost({@UBL_Tier}3, Entity.CardLeague, Entity.CardLevel, True, False, False) + 100);

  Entity.Blackboard.SetValue(eiWelaUnitPattern, [GROUP_DROP_SPAWNER], 'Units\Golems\GolemsBossGolem');
  Entity.Blackboard.SetValue(eiWelaCount, [GROUP_DROP_SPAWNER], {@UBL_SquadSize}1);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitDropMeta(Entity);

  {$IFDEF CLIENT}
    TWelaEventRedirecter.CreateGrouped(Entity, [GROUP_DROP_SPAWNER])
      .CopyValue(eiWelaAreaOfEffect, [3], [8]);
    TWelaTargetConstraintEnemiesComponent.CreateGrouped(Entity, [8]);
    TWelaTargetConstraintEventComponent.CreateGrouped(Entity, [8], eiDamageable);
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [8])
      .SetTexture('SpelltargetGeneric.png');
    TRangeIndicatorHighlightEntitiesComponent.CreateGrouped(Entity, [8]);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitDropEntity(Entity, True);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;

