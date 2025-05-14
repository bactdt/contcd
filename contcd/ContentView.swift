//
//  ContentView.swift
//  contcd
//
//  Created by txg on 2025/5/14.
//

import SwiftUI

struct Hotel: Identifiable {
    let id = UUID()
    var name: String
    var checkInDate: Date
    var customCD: Int?
}

struct ContentView: View {
    @State private var hotels: [Hotel] = []
    @State private var showingAddHotel = false
    @State private var showingHistory = false
    @State private var newHotelName = ""
    @State private var newCheckInDate = Date()
    @State private var newCustomCD: Int? = nil
    @State private var searchText = ""
    @State private var showingEditHotel = false
    @State private var currentEditHotelID: UUID? = nil
    @State private var errorMessage = ""
    @State private var showingError = false

    var filteredHotels: [Hotel] {
        let filtered = hotels.filter { calculateRemainingCDDays(hotel: $0) > 0 }
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                List {
                    ForEach(filteredHotels) { hotel in
                        NavigationLink(destination: VStack(alignment: .leading, spacing: 12) {
                            Text("酒店名称: \(hotel.name)")
                                .font(.headline)
                            Text("入住日期: \(hotel.checkInDate.formatted(date: .numeric, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("退房日期: \(calculateCheckOutDate(hotel: hotel).formatted(date: .numeric, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }) {
                            HStack {
                                Text(hotel.name)
                                    .font(.body)
                                Spacer()
                                Text("CD剩余: \(calculateRemainingCDDays(hotel: hotel))天")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(calculateRemainingCDDays(hotel: hotel) < 7 ? .red : .primary)
                            }
                            .padding(.vertical, 8)
                        }
                        .swipeActions(edge: .leading) {
                            Button(action: {
                                newHotelName = hotel.name
                                newCheckInDate = hotel.checkInDate
                                newCustomCD = hotel.customCD
                                currentEditHotelID = hotel.id
                                showingEditHotel = true
                            }) {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: { offsets in
                        deleteHotel(at: offsets, hotels: $hotels)
                    })
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("酒店CD计算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingHistory = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .symbolRenderingMode(.multicolor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHotel = true }) {
                        Image(systemName: "plus")
                            .symbolRenderingMode(.multicolor)
                    }
                }
            }
            .sheet(isPresented: $showingAddHotel) {
                VStack(spacing: 24) {
                    TextField("酒店名称", text: $newHotelName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    DatePicker("入住日期", selection: $newCheckInDate, displayedComponents: .date)
                        .padding(.horizontal)

                    TextField("自定义CD天数（可选）", value: $newCustomCD, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    HStack(spacing: 24) {
                        Button("取消") {
                            showingAddHotel = false
                            newHotelName = ""
                            newCheckInDate = Date()
                            newCustomCD = nil
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundColor(.red)

                        Button("保存") {
                            if hotels.contains(where: { $0.name == newHotelName }) {
                                // 显示错误提示
                                errorMessage = "酒店名称已存在"
                                showingError = true
                                return // 不关闭添加界面，让用户看到错误提示
                            } else {
                                let newHotel = Hotel(name: newHotelName, checkInDate: newCheckInDate, customCD: newCustomCD)
                                hotels.append(newHotel)
                                // 只有成功添加后才关闭界面并重置表单
                                showingAddHotel = false
                                newHotelName = ""
                                newCheckInDate = Date()
                                newCustomCD = nil
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .alert("错误", isPresented: $showingError) {
                    Button("确定", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(hotels: $hotels)
            }
            .sheet(isPresented: $showingEditHotel) {
                VStack(spacing: 24) {
                    TextField("酒店名称", text: $newHotelName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    DatePicker("入住日期", selection: $newCheckInDate, displayedComponents: .date)
                        .padding(.horizontal)
                    
                    TextField("自定义CD天数（可选）", value: $newCustomCD, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                    
                    HStack(spacing: 24) {
                        Button("取消") {
                            showingEditHotel = false
                            newHotelName = ""
                            newCheckInDate = Date()
                            newCustomCD = nil
                            currentEditHotelID = nil
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundColor(.red)
                        
                        Button("保存") {
                            if let hotelID = currentEditHotelID, let index = hotels.firstIndex(where: { $0.id == hotelID }) {
                                // 检查是否与其他酒店名称重复（排除当前编辑的酒店）
                                if hotels.contains(where: { $0.id != hotelID && $0.name == newHotelName }) {
                                    // 显示错误提示
                                    errorMessage = "酒店名称已存在"
                                    showingError = true
                                    return
                                }
                                hotels[index] = Hotel(name: newHotelName, checkInDate: newCheckInDate, customCD: newCustomCD)
                            }
                            showingEditHotel = false
                            newHotelName = ""
                            newCheckInDate = Date()
                            newCustomCD = nil
                            currentEditHotelID = nil
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .alert("错误", isPresented: $showingError) {
                    Button("确定", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
            }

        }
    }

    func calculateCheckOutDate(hotel: Hotel) -> Date {
        let calendar = Calendar.current
        let days = hotel.customCD ?? 30
        let checkOutDate = calendar.date(byAdding: .day, value: 1, to: hotel.checkInDate) ?? hotel.checkInDate
        return calendar.date(byAdding: .day, value: days, to: checkOutDate) ?? checkOutDate
    }

    func calculateRemainingCDDays(hotel: Hotel) -> Int {
        let calendar = Calendar.current
        let today = Date()
        let checkOutDate = calendar.date(byAdding: .day, value: 1, to: hotel.checkInDate) ?? hotel.checkInDate
        let days = hotel.customCD ?? 30
        let endDate = calendar.date(byAdding: .day, value: days, to: checkOutDate) ?? checkOutDate
        let remainingDays = calendar.dateComponents([.day], from: today, to: endDate).day ?? 0
        return max(remainingDays, 0)
    }

    func deleteHotel(at offsets: IndexSet, hotels: Binding<[Hotel]>) {
        hotels.wrappedValue.remove(atOffsets: offsets)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct HistoryView: View {
    @Binding var hotels: [Hotel]

    var body: some View {
        List {
            ForEach(hotels) { hotel in
                VStack(alignment: .leading) {
                    Text(hotel.name)
                    Text(hotel.checkInDate.formatted(date: .numeric, time: .omitted))
                }
            }
        }
        .navigationTitle("历史记录")
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("搜索酒店名称", text: $text)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
    }
}

