<?xml version="1.0"?>
<TGUIComponent type="Engine.GUI.TGUIComponent" identifier="100000">
  <FParent/>
  <FChildren type="System.Generics.Collections.TObjectList&lt;Engine.GUI.TGUIComponent&gt;" list_loader_version="1.0" OwnsObjects="True">
    <Item type="Engine.GUI.TGUIComponent">
      <FParent type="Engine.GUI.TGUIComponent" identifier="100000"/>
      <FChildren type="System.Generics.Collections.TObjectList&lt;Engine.GUI.TGUIComponent&gt;" list_loader_version="1.0" OwnsObjects="True"/>
      <FStyleSheet type="Engine.GUI.TGUIStyleSheet">
        <DataAsText>Text : -Textilein im Wald hin-\n ging allein in die weite Welt hinein. Textilei ging allein in die weite Welt hinein;
</DataAsText>
      </FStyleSheet>
      <ClassesAsText></ClassesAsText>
      <name>Hint</name>
    </Item>
    <Item type="Engine.GUI.TGUIComponent" identifier="100005">
      <FParent type="Engine.GUI.TGUIComponent" identifier="100000"/>
      <FChildren type="System.Generics.Collections.TObjectList&lt;Engine.GUI.TGUIComponent&gt;" list_loader_version="1.0" OwnsObjects="True">
        <Item type="Engine.GUI.TGUIComponent">
          <FParent type="Engine.GUI.TGUIComponent" identifier="100005"/>
          <FChildren type="System.Generics.Collections.TObjectList&lt;Engine.GUI.TGUIComponent&gt;" list_loader_version="1.0" OwnsObjects="True"/>
          <FStyleSheet type="Engine.GUI.TGUIStyleSheet">
            <DataAsText>Position : 100% 0;
Size : 65 20;
Anchor : caTopRight;
Padding : 0 17 0 0;
Text : 99999;
Fontsize : 17;
Fontflags : [ffRight];
Fontcolor : $FFFFFFFF;
</DataAsText>
          </FStyleSheet>
          <ClassesAsText></ClassesAsText>
          <name>Cost</name>
        </Item>
        <Item type="Engine.GUI.TGUIComponent">
          <FParent type="Engine.GUI.TGUIComponent" identifier="100005"/>
          <FChildren type="System.Generics.Collections.TObjectList&lt;Engine.GUI.TGUIComponent&gt;" list_loader_version="1.0" OwnsObjects="True"/>
          <FStyleSheet type="Engine.GUI.TGUIStyleSheet">
            <DataAsText>Position : 100% 0;
Size : auto 16;
Anchor : caTopRight;
Background : HUD/RessourcePanel/icon_soul_coin.png;
</DataAsText>
          </FStyleSheet>
          <ClassesAsText></ClassesAsText>
          <name>CostIcon</name>
        </Item>
      </FChildren>
      <FStyleSheet type="Engine.GUI.TGUIStyleSheet">
        <DataAsText>Position : 0 0;
Size : 100% 100%;
</DataAsText>
      </FStyleSheet>
      <ClassesAsText></ClassesAsText>
      <name>CostWrapper</name>
    </Item>
  </FChildren>
  <FStyleSheet type="Engine.GUI.TGUIStyleSheet">
    <DataAsText></DataAsText>
  </FStyleSheet>
  <ClassesAsText></ClassesAsText>
  <name>Hintbox</name>
</TGUIComponent>
