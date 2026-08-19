Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # 鉢に貼ったQRコードから開く、購入者向けの公開ページ。
  # QRの情報量を抑えるためパスは短くする。
  get "/p/:token", to: "public/stocks#show", as: :public_stock

  namespace :admin do
    root "dashboard#index"
    resource :data_export, only: :show
    resources :plants
    resources :locations
    resources :production_lots, only: %i[index show new create]
    resources :nursery_groups, only: %i[index show edit update] do
      member do
        get :advance, action: :advance_form
        post :advance
        get :correct_quantity, action: :correct_quantity_form
        patch :correct_quantity
        get :pot_up, action: :pot_up_form
        post :pot_up
      end
    end
    resources :stocks, except: :destroy do
      member do
        get :advance_stage, action: :advance_stage_form
        patch :advance_stage
        get :sale_ready, action: :sale_ready_form
        patch :mark_sale_ready
        patch :revoke_sale_ready
        get :complete, action: :complete_form
        patch :complete
      end
    end
    resources :stock_observations
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
