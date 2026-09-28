extends Node
## Desktop stub for ads/IAP. On Android, swap in AdMob + Play Billing plugins.
## Policy: levels 1–5 free of forced ads; from level 6+, 1 interstitial every 3 clears.

signal interstitial_requested
signal rewarded_hint_granted
signal purchase_completed(product_id: String)

const PRODUCT_UNLOCK: String = "unlock_full_game_199"
const FREE_AD_LEVELS: int = 5
const INTERSTITIAL_EVERY: int = 3

var _ads_enabled: bool = true


func _ready() -> void:
	_ads_enabled = not GameState.is_premium
	print("[Monetization] Ready (desktop stub). premium=", GameState.is_premium)


func on_level_complete(level_id: int, total_clears: int) -> void:
	if GameState.is_premium or not _ads_enabled:
		return
	if level_id <= FREE_AD_LEVELS:
		return
	if total_clears % INTERSTITIAL_EVERY == 0:
		show_interstitial_ad()


func show_interstitial_ad() -> void:
	interstitial_requested.emit()
	print("[Monetization] Interstitial would show (stub). clears cascade OK.")


func request_hint_reward() -> void:
	## Rewarded video stub — grants hint immediately on desktop.
	print("[Monetization] Rewarded hint granted (stub).")
	rewarded_hint_granted.emit()


func buy_full_game_unlock() -> void:
	## Call GooglePlayBilling.purchase(PRODUCT_UNLOCK) on Android.
	print("[Monetization] Purchase stub success: ", PRODUCT_UNLOCK)
	_on_purchase_success(PRODUCT_UNLOCK)


func _on_purchase_success(product_id: String) -> void:
	if product_id == PRODUCT_UNLOCK:
		GameState.set_premium(true)
		purchase_completed.emit(product_id)


func apply_premium_status(enabled: bool) -> void:
	_ads_enabled = not enabled
	if enabled:
		hide_all_ads()


func hide_all_ads() -> void:
	print("[Monetization] All ads hidden.")


func should_show_ads() -> bool:
	return _ads_enabled and not GameState.is_premium
