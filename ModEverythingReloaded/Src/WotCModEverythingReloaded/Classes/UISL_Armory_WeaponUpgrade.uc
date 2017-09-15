class UISL_Armory_WeaponUpgrade extends UIScreenListener dependson(UIInputDialogue) config (WeaponCustomisation);

var UIArmory_WeaponUpgrade WeaponUpgradeScreen;
var localized string m_strCustomizeWeaponName;
var config int WEAPON_NICKNAME_NAME_MAXCHARS;

event OnInit(UIScreen Screen)
{
	if (UIArmory_WeaponUpgrade(Screen)==none)
		return;

	OnReceiveFocus(Screen);
}

event OnReceiveFocus(UIScreen Screen)
{
	local TWeaponUpgradeAvailabilityData WeaponUpgradeAvailabilityData;
	local XComGameState_Item Weapon;
	//local EInventorySlot slot;

	if (UIArmory_WeaponUpgrade(Screen)==none)
		return;
	WeaponUpgradeScreen = UIArmory_WeaponUpgrade(Screen);

	WeaponUpgradeScreen.CustomizeList.OnItemClicked = Override_CustomizeItemClicked;
	WeaponUpgradeScreen.UpdateCustomization(none);
	
	//slot = X2WeaponTemplate(XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponUpgradeScreen.WeaponRef.ObjectID))
	//	.GetMyTemplate()).InventorySlot;
	
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponUpgradeScreen.WeaponRef.ObjectID));
	GetWeaponUpgradeAvailability(Weapon, WeaponUpgradeAvailabilityData);

	`LOG("WeaponUpgradeScreen" @ WeaponUpgradeScreen.SlotsList.OnItemClicked,, 'ModEverythingReloaded');
	`LOG("bHasModularWeapons" @ WeaponUpgradeAvailabilityData.bHasModularWeapons,, 'ModEverythingReloaded');

	if( !WeaponUpgradeAvailabilityData.bHasModularWeapons )
	{
		WeaponUpgradeScreen.SlotsList.OnItemClicked = Override_OnItemClicked;
	}

}
simulated function Override_CustomizeItemClicked(UIList ContainerList, int ItemIndex)
{
	`LOG("Override_CustomizeItemClicked" @ WeaponUpgradeScreen.GetCustomizeItem(0),, 'ModEverythingReloaded');
	WeaponUpgradeScreen.GetCustomizeItem(0).OnClickDelegate = OpenWeaponNameInputBox_Override;
}

simulated function Override_OnItemClicked(UIList ContainerList, int ItemIndex)
{
	`LOG("Override_OnItemClicked" @ ContainerList @ WeaponUpgradeScreen.SlotsList @ ItemIndex,, 'ModEverythingReloaded');
	if (ContainerList == WeaponUpgradeScreen.SlotsList)
	{
		WeaponUpgradeScreen.Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		return;
	}
}

simulated function OpenWeaponNameInputBox_Override()
{
	local TInputDialogData kData;

	kData.strTitle = m_strCustomizeWeaponName;
	kData.iMaxChars = WEAPON_NICKNAME_NAME_MAXCHARS;
	kData.strInputBoxText = WeaponUpgradeScreen.UpdatedWeapon.Nickname;
	kData.fnCallback = WeaponUpgradeScreen.OnNameInputBoxClosed;
	`log("Opening UIInputDialog '" $ kData.strTitle $ "' - max " $ kData.iMaxChars $ " characters");
	WeaponUpgradeScreen.Movie.Pres.UIInputDialog(kData);
}

simulated static function GetWeaponUpgradeAvailability(XComGameState_Item Weapon, out TWeaponUpgradeAvailabilityData WeaponUpgradeAvailabilityData)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2WeaponTemplate WeaponTemplate;
	local int AvailableSlots, EquippedUpgrades;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	WeaponTemplate = X2WeaponTemplate(Weapon.GetMyTemplate());

	if (WeaponTemplate != none)
	{
		EquippedUpgrades = Weapon.GetMyWeaponUpgradeTemplateNames().Length;
		AvailableSlots = WeaponTemplate.NumUpgradeSlots;
	}

	if (AvailableSlots <= 0)
		AvailableSlots = 1;
	// Only add extra slots if the weapon had some to begin with
	if (AvailableSlots > 0)
	{
		if (XComHQ.bExtraWeaponUpgrade)
			AvailableSlots++;

		if (XComHQ.ExtraUpgradeWeaponCats.Find(WeaponTemplate.WeaponCat) != INDEX_NONE)
			AvailableSlots++;
	}

	WeaponUpgradeAvailabilityData.bCanWeaponBeUpgraded = (AvailableSlots > 0);
	WeaponUpgradeAvailabilityData.bHasWeaponUpgradeSlotsAvailable = (AvailableSlots > EquippedUpgrades);
	WeaponUpgradeAvailabilityData.bHasWeaponUpgrades = XComHQ.HasWeaponUpgradesInInventory();
	WeaponUpgradeAvailabilityData.bHasModularWeapons = XComHQ.bModularWeapons;
}

defaultproperties
{
	ScreenClass=none
}