# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# スケジューリングエンジン（ReviewScheduler / DailyPlanner / PaceCalculator）の
# 入出力を確認するためのサンプルデータ。find_or_create_by! で冪等にする。
#
# 日付は固定のアンカー日を基準にする。Date.current を使うと実行日ごとに
# studied_on / scheduled_on が変わり、find_or_create_by! の検索キーがずれて
# 重複レコードが増えてしまうため。
anchor = Date.new(2026, 6, 28)

user = User.find_or_create_by!(google_uid: "seed-google-uid") do |u|
  u.email = "seed@example.com"
  u.name = "Seed User"
end

material = Material.find_or_create_by!(user:, title: "リーダブルコード") do |m|
  m.total_amount = 4
  m.unit_label = "章"
  m.deadline = anchor + 14
end

study_unit_attributes = [
  { title: "第1章 理解しやすいコード", position: 1, estimated_minutes: 30 },
  { title: "第2章 名前に情報を込める", position: 2, estimated_minutes: 45 },
  { title: "第3章 誤解されない名前", position: 3, estimated_minutes: 40 },
  { title: "第4章 美しさ",            position: 4, estimated_minutes: 25 }
]

study_units = study_unit_attributes.map do |attrs|
  material.study_units.find_or_create_by!(title: attrs[:title]) do |unit|
    unit.position = attrs[:position]
    unit.estimated_minutes = attrs[:estimated_minutes]
  end
end

# 学習ログ：理解度評価 ★1〜3 で記録する
# 第1章：復習を重ねて定着が進んでいる例
first_unit = study_units[0]
[
  { studied_on: anchor - 8, rating: 2, duration_minutes: 35 },
  { studied_on: anchor - 5, rating: 3, duration_minutes: 20 }
].each do |attrs|
  first_unit.study_logs.find_or_create_by!(studied_on: attrs[:studied_on]) do |log|
    log.rating = attrs[:rating]
    log.duration_minutes = attrs[:duration_minutes]
  end
end

# 第2章：直近に学習したが理解度が低くリセットが必要な例（★1）
second_unit = study_units[1]
second_unit.study_logs.find_or_create_by!(studied_on: anchor - 2) do |log|
  log.rating = 1
  log.duration_minutes = 50
end

# 復習予定：第1章は伸ばした予定、第2章は★1なので翌日に再設定
first_unit.review_schedules.find_or_create_by!(scheduled_on: anchor + 6) do |schedule|
  schedule.review_count = 2
  schedule.completed = false
end

second_unit.review_schedules.find_or_create_by!(scheduled_on: anchor + 1) do |schedule|
  schedule.review_count = 0
  schedule.completed = false
end

puts "Seeded: users=#{User.count}, materials=#{Material.count}, " \
     "study_units=#{StudyUnit.count}, study_logs=#{StudyLog.count}, " \
     "review_schedules=#{ReviewSchedule.count}"
