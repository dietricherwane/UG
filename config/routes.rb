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

  # Loto
  get '/loto/main_menu' => 'loto#index', as: :loto_main_menu
  get '/loto/bet_selection/:drawing' => 'loto#bet_selection', as: :loto_bet_selection
  get '/loto/formula_selection/:bet' => 'loto#formula_selection', as: :loto_formula_selection
  get '/loto/bet/:formula' => 'loto#bet', as: :loto_bet
  post '/loto/select_bet' => 'loto#select_bet', as: :loto_select_bet
  post '/loto/place_bet' => 'loto#place_bet', as: :loto_place_bet
  get '/loto/list_bets' => 'loto#list_bets', as: :loto_list_bets

  # PMU PLR
  get '/plr/list_bets' => 'plr#list_bets', as: :plr_bets

  # PMU ALR
  get '/pmu_alr/list_bets' => 'pmu_alr#list_bets', as: :pmu_alr_bets

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
