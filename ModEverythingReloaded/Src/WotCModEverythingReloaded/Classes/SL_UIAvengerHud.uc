class SL_UIAvengerHud extends UIScreenListener;

var UIAvengerHud AvengerHud;
var Object ListenerObj;
// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{
	AvengerHud = UIAvengerHud(Screen);
	if (AvengerHud == none)
		return;
	ListenerObj = self;
	`XEVENTMGR.RegisterForEvent(ListenerObj, 'OnArmoryMainMenuUpdate', self.OnArmoryMainMenuUpdate, ELD_Immediate);
}

function EventListenerReturn OnArmoryMainMenuUpdate(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local UIList Menu;
	local UIListItemString WeaponUpgradeButton;

	Menu = UIList(EventData);
	WeaponUpgradeButton = UIListItemString(Menu.GetItem(3));
	WeaponUpgradeButton.ButtonBG.OnClickedDelegate = self.OnWeaponUpgrade;
	WeaponUpgradeButton.SetText(class'UIArmory_EquipmentSelect'.default.m_strListTitle);
	return ELR_NoInterrupt;

}
simulated function OnWeaponUpgrade(UIButton kButton)
{
	local XComHQPresentationLayer HQPres;
	local UIArmory_MainMenu MainMenu;
	local UIArmory_EquipmentSelect EquipmentSelect;

	if(CheckForDisabledListItem(kButton)) return;
	MainMenu = UIArmory_MainMenu(`SCREENSTACK.GetCurrentScreen());
	HQPres = XComHQPresentationLayer(MainMenu.Movie.Pres);	
	if( HQPres != none) 
	{
		
		MainMenu.ReleasePawn();
		EquipmentSelect = UIArmory_EquipmentSelect(`SCREENSTACK.Push(HQPres.Spawn(class'UIArmory_EquipmentSelect', MainMenu), HQPres.Get3DMovie()));
		EquipmentSelect.InitArmory(MainMenu.UnitReference);					

		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
	}
}
simulated function bool CheckForDisabledListItem(UIButton kButton)
{
	local UIListItemString Parent;

	Parent = UIListItemString(kButton.ParentPanel);
	if( Parent != none && Parent.bDisabled )
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
		return true;
	}
	return false;
}
defaultproperties
{
	ScreenClass=none
}