local PowerConfig = {

	DefaultPower = "None",

	Powers = {

		-----------------------------------------------------------------------
		-- NO POWER
		-----------------------------------------------------------------------
		None = {
			DisplayName = "None",
			PunchDamage = 10,
			Abilities = {}
		},


		-----------------------------------------------------------------------
		-- BRUTE POWER
		-----------------------------------------------------------------------
		Brute = {
			DisplayName = "Brute",
			PunchDamage = 20,

			Abilities = {

				-- Q Ability: Ground Slam (Animation Driven)
				GroundSlam = {
					Id = "GroundSlam",
					KeyCode = "Q",

					Animation = "rbxassetid://121265557126091",

					Event1 = "e1",  -- sound moment
					Event2 = "e2",  -- damage moment

					Radius = 18,
					Damage = 28,
					KnockbackStrength = 80,
					Cooldown = 6,
				},

				-- R Ability: Heavy Punch (Tap)
				HeavyPunch = {
					Id = "HeavyPunch",
					KeyCode = "R",

					Animation = "rbxassetid://PUT_YOUR_HEAVYPUNCH_ANIM_ID_IF_YOU_WANT", -- optional

					Damage = 25,
					Range = 6,
					Cooldown = 3,
				},
			}
		},


		-----------------------------------------------------------------------
		-- LIGHTNING POWER
		-----------------------------------------------------------------------
		Lightning = {
			DisplayName = "Lightning",
			PunchDamage = 14,

			Abilities = {

				-- Q Ability: Lightning Beam (Hold)
				LightningBeam = {
					Id = "LightningBeam",
					KeyCode = "Q",

					Animation = "rbxassetid://PUT_YOUR_LIGHTNING_BEAM_CAST_ANIM", -- optional

					Holdable = true,
					MaxHoldTime = 3,

					TickDamage = 3,
					TickInterval = 0.15,
					Range = 70,
					Cooldown = 7,
				},

				-- R Ability: Lightning Dash (Tap)
				LightningDash = {
					Id = "LightningDash",
					KeyCode = "R",

					Animation = "rbxassetid://PUT_YOUR_DASH_ANIMATION_ID", -- optional

					DashDistance = 14,
					Cooldown = 4,
				},
			}
		},


		-----------------------------------------------------------------------
		-- WIND POWER
		-----------------------------------------------------------------------
		Wind = {
			DisplayName = "Wind",
			PunchDamage = 12,

			Abilities = {

				-- Q Ability: Wind Gust (AoE Push)
				WindGust = {
					Id = "WindGust",
					KeyCode = "Q",

					Animation = "rbxassetid://PUT_WIND_GUST_ANIM_ID", -- optional

					Range = 20,
					KnockbackStrength = 65,
					Damage = 15,
					Cooldown = 5,
				},

				-- R Ability: Wind Dash
				WindDash = {
					Id = "WindDash",
					KeyCode = "R",

					Animation = "rbxassetid://PUT_WIND_DASH_ANIM_ID", -- optional

					DashDistance = 18,
					Cooldown = 4,
				},
			}
		},
	}
}

return PowerConfig
