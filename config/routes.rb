Rails.application.routes.draw do

  root 'home#get_msisdn'

  post '/main_menu' => 'home#index', as: :main_menu
  get '/gaming_menu' => 'home#main_menu', as: :gaming_menu
  post '/parionsdirect_account/create' => 'home#create_parionsdirect_account', as: :create_parionsdirect_account
  get '/games/list' => 'home#list_games', as: :list_games
  post '/parionsdirect_account/authenticate' => 'home#authenticate_parionsdirect_account', as: :authenticate_parionsdirect_account
  post '/paymoney_account/validate' => 'home#validate_paymoney_account', as: :validate_paymoney_account
  get '/paymoney_account/create' => 'home#create_paymoney_account', as: :create_paymoney_account
  get '/paymoney_balance' => 'home#paymoney_balance', as: :paymoney_balance
  post '/paymoney_balance/get' => 'home#get_paymoney_balance', as: :get_paymoney_balance
  get '/other_account/paymoney_balance' => 'home#other_account_paymoney_balance', as: :other_account_paymoney_balance
  post '/other_account/paymoney_balance/get' => 'home#get_other_paymoney_balance', as: :get_other_paymoney_balance
  get '/saved_paymoney_account' => 'home#saved_paymoney_account', as: :saved_paymoney_account
  post '/saved_paymoney_account/update' => 'home#update_saved_paymoney_account', as: :update_saved_paymoney_account
  get '/games/list_bets' => 'home#list_games_bets', as: :list_game_bets
  get '/games/otp' => 'home#otp', as: :otp
  get '/games/other_otp' => 'home#other_otp', as: :other_otp
  post '/games/otp/list' => 'home#list_otp', as: :list_otp
  post '/games/other_otp/list' => 'home#list_other_otp', as: :list_other_otp

  # Loto
  get '/loto/main_menu' => 'loto#index', as: :loto_main_menu
  get '/loto/bet_selection/:drawing' => 'loto#bet_selection', as: :loto_bet_selection
  get '/loto/formula_selection/:bet' => 'loto#formula_selection', as: :loto_formula_selection
  get '/loto/bet/:formula' => 'loto#bet', as: :loto_bet
  post '/loto/select_bet' => 'loto#select_bet', as: :loto_select_bet
  post '/loto/place_bet' => 'loto#place_bet', as: :loto_place_bet
  get '/loto/list_bets' => 'loto#list_bets', as: :loto_list_bets

  # PMU PLR
  get 'plr' => 'plr#index', as: :plr
  get 'plr/reunions/list' => 'plr#list_reunions', as: :plr_list_reunions
  get 'plr/races/list' => 'plr#list_races', as: :plr_list_races
  post 'plr/race_selection' => 'plr#race_selection', as: :plr_race_selection
  post 'plr/game_selection' => 'plr#game_selection', as: :plr_game_selection
  get 'plr/races_list' => 'plr#races_list', as: :plr_races_list
  get 'plr/bet_type' => 'plr#bet_type', as: :plr_bet_type
  get '/plr/select_formula/:bet_type' => 'plr#select_formula', as: :plr_select_formula
  get '/plr/formula_selection/:formula' => 'plr#formula_selection', as: :plr_formula_selection
  post '/plr/base_selection' => 'plr#base_selection', as: :plr_base_selection
  post 'plr/selection' => 'plr#selection', as: :plr_selection
  post 'plr/total_selection' => 'plr#total_selection', as: :plr_total_selection
  post 'plr/stake_selection' => 'plr#stake_selection', as: :plr_stake_selection
  post 'plr/alternative_stake_selection' => 'plr#alternative_stake_selection', as: :plr_alternative_stake_selection
  post 'plr/bet' => 'plr#bet', as: :plr_bet
  post 'plr/bet/evaluate' => 'plr#evaluate_bet', as: :plr_evaluate_bet
  post 'plr/bet/place' => 'plr#place_bet', as: :plr_place_bet
  get '/plr/list_bets' => 'plr#list_bets', as: :plr_bets


  # PMU ALR
  get '/pmu_alr/list_bets' => 'pmu_alr#list_bets', as: :pmu_alr_bets
  get '/pmu_alr' => 'pmu_alr#index', as: :pmu_alr
  get '/pmu_alr/bet_type/:national' => 'pmu_alr#bet_type', as: :pmu_alr_bet_type
  get '/pmu_alr/generic_formula_selection/:bet_type' => 'pmu_alr#generic_formula_selection', as: :pmu_alr_generic_formula_selection
  get '/pmu_alr/multi_formula_selection' => 'pmu_alr#multi_formula_selection', as: :pmu_alr_multi_formula_selection
  get '/pmu_alr/validate_multi_formula_selection/:multi_type' => 'pmu_alr#validate_multi_formula_selection', as: :pmu_alr_validate_multi_formula_selection
  get '/pmu_alr/select_horses/:alr_formula' => 'pmu_alr#select_horses', as: :pmu_alr_select_horses
  get '/pmu_alr/select_base/:alr_formula' => 'pmu_alr#select_base', as: :pmu_alr_select_base
  post '/pmu_alr/validate_base' => 'pmu_alr#validate_base', as: :pmu_alr_validate_base
  post '/pmu_alr/stake' => 'pmu_alr#stake', as: :pmu_alr_stake
  post '/pmu_alr/evaluate_bet' => 'pmu_alr#evaluate_bet', as: :pmu_alr_evaluate_bet
  post '/pmu_alr/place_bet' => 'pmu_alr#place_bet', as: :pmu_alr_place_bet

  # SPORTCASH
  get '/sportcash/list_bets' => 'sportcash#list_bets', as: :sportcash_bets

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
