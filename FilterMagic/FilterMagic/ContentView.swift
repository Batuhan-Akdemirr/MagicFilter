//
//  ContentView.swift
//  FilterMagic
//
//  Created by Batuhan Akdemir on 26.12.2023.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import StoreKit

struct ContentView: View {
    
    
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.0
    @State private var filterScale = 0.0
    
    @State private var selectedItem : PhotosPickerItem?
    
    @State private var currentFilter : CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    @State private var showingFilters = false
    
    @State private var beginImage : CIImage?
    
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    @AppStorage("filterIsShowed") var filterIsShowed = false
    
    let maxFilterCount = 5
    
    private var isNotImage : Bool {
          selectedItem == nil
    }

    
    var body: some View {
       
        NavigationStack {
            VStack {
                
                Spacer()

                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("No picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem , loadImage)
             
                Spacer()

                
                VStack {
                    
                    if currentFilter.inputKeys.contains(kCIInputIntensityKey) {
                        HStack {
                            Text("Intensity")
                            Slider(value: $filterIntensity)
                                .onChange(of: filterIntensity , applyProcessing)
                        }
                    }
                    
                    if currentFilter.inputKeys.contains(kCIInputRadiusKey) {
                        HStack {
                            Text("Radius")
                            Slider(value: $filterRadius, in: 0...200)
                                .onChange(of: filterRadius , applyProcessing)
                        }
                    }
                    
                    if currentFilter.inputKeys.contains(kCIInputScaleKey) {
                        HStack {
                            Text("Scale")
                            Slider(value: $filterScale, in: 0...10)
                                .onChange(of: filterScale , applyProcessing)
                        }
                    }
                    
                }
                .disabled(isNotImage)
                .padding(.vertical)

                HStack {
                    Button("Change Filter", action: changeFilter)
                        .disabled(isNotImage)

                    Spacer()

                    if let processedImage {
                        ShareLink(item: processedImage , preview: SharePreview("MagicFilter image", image: processedImage))
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("MagicFilter")
            .confirmationDialog("Select a filter ", isPresented: $showingFilters) {
                Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                Button("Edges") { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Cancel", role: .cancel) { }
            }
        }
        
    }
    


    private func changeFilter() {
        showingFilters = true
    }
    
    private func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            
            guard let inputImage = UIImage(data: imageData) else { return }
            
            beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    private func applyProcessing() {
       
    
        let inputKeys = currentFilter.inputKeys

        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius , forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue( filterScale, forKey: kCIInputScaleKey) }
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let uıImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uıImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
         currentFilter = filter
         loadImage()
        
        filterCount += 1
        
        if  filterCount >= maxFilterCount && filterIsShowed == false{
            filterIsShowed = true
            requestReview()
        }
                  
     }
}

#Preview {
    ContentView()
}
