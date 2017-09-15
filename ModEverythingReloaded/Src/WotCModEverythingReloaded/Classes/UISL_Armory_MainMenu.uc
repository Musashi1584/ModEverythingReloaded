class UISL_Armory_MainMenu extends UIScreenListener;

var UIArmory_MainMenu ArmoryMainMenu;
var delegate<OnItemSelectedCallback> NextOnItemClicked;
delegate OnItemSelectedCallback(UIList _list, int itemIndex);

event OnInit(UIScreen Screen)
{
	if (UIArmory_MainMenu(Screen) != none) {
		ArmoryMainMenu = UIArmory_MainMenu(Screen);
		NextOnItemClicked = ArmoryMainMenu.List.OnItemClicked;
		ArmoryMainMenu.List.OnItemClicked = OnItemClicked;
	}
}

event OnReceiveFocus(UIScreen Screen)
{
	if (UIArmory_MainMenu(Screen) != none) {
		ArmoryMainMenu = UIArmory_MainMenu(Screen);
	}
}

event OnRemoved(UIScreen Screen)
{
	if (UIArmory_MainMenu(Screen) != none) {
		ArmoryMainMenu = none;
	}
}

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	local UIListItemString CustomizeWeaponListItem; 

	CustomizeWeaponListItem = FindListItem(ContainerList, ArmoryMainMenu.m_strCustomizeWeapon);

	if (ContainerList.GetItem(ItemIndex) == CustomizeWeaponListItem)
	{
		OnCustomizWeaponButtonCallback(CustomizeWeaponListItem);
		return;
	}

	NextOnItemClicked(ContainerList, ItemIndex);
}

simulated function OnCustomizWeaponButtonCallback(UIListItemString CustomizeWeaponListItem)
{
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPRES;

	if(CustomizeWeaponListItem.bDisabled)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
		return;
	}

	ArmoryMainMenu.ReleasePawn();
	
	if(HQPres != none) 
	{
		if(`SCREENSTACK.IsNotInStack(class'UIArmory_EquipmentSelect'))
		{
			UIArmory_EquipmentSelect(`SCREENSTACK.Push(ArmoryMainMenu.Movie.Pres.Spawn(class'UIArmory_EquipmentSelect', ArmoryMainMenu), ArmoryMainMenu.Movie.Pres.Get3DMovie())).InitArmory(ArmoryMainMenu.UnitReference);		
		}
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
	}
}

simulated function OnDismissButtonCallback()
{
	ArmoryMainMenu.OnDismissUnit();
}

simulated function UIListItemString FindListItem(UIList List, String Text)
{
	local int Idx;
	local UIListItemString Current;

	for (Idx = 0; Idx < List.ItemCount ; Idx++)
	{
		Current = UIListItemString(List.GetItem(Idx));
		if (Current.Text == Text)
			return Current;
	}
	return none;
}

defaultproperties
{
	ScreenClass = none
}