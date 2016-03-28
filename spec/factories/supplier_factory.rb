FactoryGirl.define do
  factory :supplier, :class => Spree::Supplier do
    name 'Test Supplier'
    abbreviation 'TEST'
    account_number '1234567'
    email 'zach@800ceoread.com'
    phone '123-456-7890'
  end
end
