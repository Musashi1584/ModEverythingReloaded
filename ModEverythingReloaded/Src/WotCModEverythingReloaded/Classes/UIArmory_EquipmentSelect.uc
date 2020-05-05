class UIArmory_EquipmentSelect extends UIArmory config(WeaponCustomisation);

var config bool ALLOW_SECONDARY;
var config bool ALLOW_ARMOR;
var config bool ALLOW_HEAVY;
var config bool ALLOW_UTILITY;
var config array<EInventorySlot> ALLOWED_SLOTS;
var localized string m_strListTitle;

// the equipment list
var UIPanel EquipmentListContainer;
var UIList EquipmentList;
var int FontSize;

simulated function InitArmory(StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
	super.InitArmory(UnitRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant, InitCheckGameState);

	`HQPRES.CAMLookAtNamedLocation( CameraTag, 0 );

	FontSize = bIsIn3D ? class'UIUtilities_Text'.const.BODY_FONT_SIZE_3D : class'UIUtilities_Text'.const.BODY_FONT_SIZE_2D;
	
	EquipmentListContainer = Spawn(class'UIPanel', self);
	EquipmentListContainer.bAnimateOnInit = false;
	EquipmentListContainer.InitPanel('leftPanel');
	EquipmentList = class'UIArmory_Loadout'.static.CreateList(EquipmentListContainer);
	EquipmentList.OnItemClicked = OnItemClicked;

	`LOG("EquipmentList" @ EquipmentList @ EquipmentList.OnItemClicked,,'ModEverythingReloaded');

	MC.FunctionString("setLeftPanelTitle", m_strListTitle);

	PopulateData();
}
simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	PopulateData();
}

simulated function PopulateData()
{
	CreateSoldierPawn();
	UpdateEquipmentList();
	DisplayList();

	Navigator.SetSelected(EquipmentListContainer);
	EquipmentListContainer.Navigator.SetSelected(EquipmentList);
	if (EquipmentList.SelectedIndex == INDEX_NONE)
		EquipmentList.SetSelectedIndex(0);
}

// called by UIArmory
simulated function OnAccept()
{
    if (EquipmentList.SelectedIndex != INDEX_NONE)
    {
        OnItemClicked(EquipmentList, EquipmentList.SelectedIndex);
    }
}

simulated function XComGameState_Item GetEquippedItem(EInventorySlot eSlot)
{
	return GetUnit().GetItemInSlot(eSlot, CheckGameState);
}

simulated function array<XComGameState_Item> GetAllEquippedItem(EInventorySlot eSlot)
{
	return GetUnit().GetAllItemsInSlot(eSlot, CheckGameState);
}

simulated function UpdateEquipmentList()
{
	local UIArmory_LoadoutItem Item;
	local array<XComGameState_Item> SlotItems;
	local XComGameState_Item SlotItem;
	local EInventorySlot InvSlot;

	EquipmentList.ClearItems();

	// Clear out tooltips from removed list items
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(EquipmentList.MCPath));

	Item = UIArmory_LoadoutItem(EquipmentList.CreateItem(class'UIArmory_LoadoutItem'));
	Item.InitLoadoutItem(GetEquippedItem(eInvSlot_PrimaryWeapon), eInvSlot_PrimaryWeapon, true);

	if (default.ALLOW_SECONDARY)
	{
		SlotItem = GetEquippedItem(eInvSlot_SecondaryWeapon);
		if (SlotItem != none)
		{
			Item = UIArmory_LoadoutItem(EquipmentList.CreateItem(class'UIArmory_LoadoutItem'));
			Item.InitLoadoutItem(SlotItem, eInvSlot_SecondaryWeapon, true);
		}
	}
	if (default.ALLOW_HEAVY)
	{
		SlotItem = GetEquippedItem(eInvSlot_HeavyWeapon);
		if (SlotItem != none)
		{
			Item = UIArmory_LoadoutItem(EquipmentList.CreateItem(class'UIArmory_LoadoutItem'));
			Item.InitLoadoutItem(SlotItem, eInvSlot_HeavyWeapon, true);
		}
	}
	if (default.ALLOW_ARMOR)
	{
		Item = UIArmory_LoadoutItem(EquipmentList.CreateItem(class'UIArmory_LoadoutItem'));
		Item.InitLoadoutItem(GetEquippedItem(eInvSlot_Armor), eInvSlot_Armor, true);
	}
	if (default.ALLOW_UTILITY)
	{
		SlotItems = GetAllEquippedItem(eInvSlot_Utility);
		foreach SlotItems(SlotItem)
		{
			if (SlotItem != none && SlotItem.GetMyTemplate().iItemSize > 0)
			{
				`LOG("Adding" @ SlotItem.GetMyTemplateName() @ "to upgradable items",,'ModEverythingReloaded');
				Item = UIArmory_LoadoutItem(EquipmentList.CreateItem(class'UIArmory_LoadoutItem'));
				Item.InitLoadoutItem(SlotItem, eInvSlot_Utility, true);
			}
		}
	}

	foreach default.ALLOWED_SLOTS(InvSlot)
	{
		SlotItem = GetEquippedItem(InvSlot);
		if (SlotItem != none)
		{
			Item = UIArmory_LoadoutItem(EquipmentList.CreateItem(class'UIArmory_LoadoutItem'));
			Item.InitLoadoutItem(SlotItem, InvSlot, true);
		}
	}
}

simulated function DisplayList()
{
	// unlock selected item
	UIArmory_LoadoutItem(EquipmentList.GetSelectedItem()).SetLocked(false);
	// disable list item selection on LockerList, enable it on EquipmentList
	EquipmentListContainer.EnableMouseHit();
	Header.PopulateData(GetUnit());
}

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	local UIArmory_WeaponUpgrade WeaponUpgradeScreen;
	`LOG("EquipmentList OnItemClicked" @ UIArmory_LoadoutItem(ContainerList.GetItem(ItemIndex)).IsDisabled,,'ModEverythingReloaded');

	if(UIArmory_LoadoutItem(ContainerList.GetItem(ItemIndex)).IsDisabled)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		return;
	}
	ReleasePawn();

	// launch the weapon upgrade screen with the weapon selected
	if(`SCREENSTACK.IsNotInStack(class'UIArmory_WeaponUpgrade'))
	{
		WeaponUpgradeScreen = UIArmory_WeaponUpgrade(`SCREENSTACK.Push(Movie.Pres.Spawn(class'UIArmory_WeaponUpgrade', self), Movie.Pres.Get3DMovie()));
		`LOG("UIArmory_WeaponUpgrade IsNotInStack" @ `SCREENSTACK.IsNotInStack(class'UIArmory_WeaponUpgrade') @ UIArmory_LoadoutItem(EquipmentList.GetSelectedItem()).ItemRef.ObjectID @ WeaponUpgradeScreen.IsVisible,, 'ModEverythingReloaded');
		WeaponUpgradeScreen.InitArmory(UIArmory_LoadoutItem(EquipmentList.GetSelectedItem()).ItemRef);
	}
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");	
}

simulated function OnCancel()
{
	super.OnCancel(); // exits screen
}


defaultproperties
{
	LibID="LoadoutScreenMC"
	DisplayTag="UIBlueprint_Loadout"
	CameraTag="UIBlueprint_Loadout"
	bAutoSelectFirstNavigable=false
}