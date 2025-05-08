//
//  ContentView.swift
//  TapOnPhoneExample
//
//  Created by Wellington Hirsch on 11/02/25.
//

import SwiftUI
import TapOnPhoneSDK

struct ContentView: View {
    
    @State private var isLoadingInitialization = false
    @State private var isInitialized = false
    @State private var initializeError: TapOnPhoneError?
    
    @State private var amount: Int = 1
    @State private var paymentType: TapOnPhonePaymentType = .credit
    @State private var installments: Int = 1
    @State private var metadata: String = ""
    
    @State private var isLoadingPayment = false
    @State private var paySuccess: PaymentApprovedResponse?
    @State private var payError: PaymentErrorResponse?
    
    var body: some View {
        VStack {
            Text("TapOnPhone Example")
                .bold()
            
            /// You always can know the SDK version using the TapOnPhone.getVersion() method
            Text("SDK version: \(TapOnPhone.getVersion())")
            
            Spacer()
            
            Button {
                isLoadingInitialization = true
                
                /// When the app opens or the user triggers some event of your choice. You NEED to call TapOnPhone.initialize()
                /// to initialize the SDK. You choose the moment, but ALWAYS should happen before calling TapOnPhone.pay().
                TapOnPhone.initialize(
                    credentials: TapOnPhoneCredentials(
                        marketplace: "",
                        seller: "",
                        accessKey: ""
                    ),
                    logLevel: TapOnPhoneLogLevel.information,
                    onSuccess: {
                        isLoadingInitialization = false
                        isInitialized = true
                    },
                    onError: { error in
                        isLoadingInitialization = false
                        isInitialized = false
                        initializeError = error
                    }
                )
            } label: {
                Text("1. Initialize SDK")
                    .bold()
            }
            
            initializationStatus
            
            Spacer()
            
            payFields
            
            Button {
                isLoadingPayment = true
                
                /// After the SDK has been initialized with success, you can capture the payment values like amount, installments,
                /// payment type and send to the TapOnPhone.pay() to do a payment.
                TapOnPhone.pay(
                    payRequest: PaymentRequest(
                        amount: Decimal(Double(amount) / 100.0),
                        paymentType: paymentType,
                        installments: installments,
                        metadata: metadata
                    ),
                    onApproved: { success in
                        isLoadingPayment = false
                        paySuccess = success
                    },
                    onError: { error in
                        isLoadingPayment = false
                        payError = error
                    }
                )
            } label: {
                Text("2. Pay")
                    .bold()
            }
            .disabled(!isInitialized)
            
            payStatus
            
            Spacer()
        }
        .padding()
    }
}

extension ContentView {
    
    var initializationStatus: some View {
        if isLoadingInitialization {
            Text("Loading...")
        } else if isInitialized {
            Text("Status: Initialized")
        } else if let initializeError {
            Text("Error: [\(initializeError.code.rawValue)] \(initializeError.message)")
        } else {
            Text("Status: Not initialized")
        }
    }
    
    var payFields: some View {
        VStack {
            TextField("Amount", value: $amount, format: .number)
                .textFieldStyle(.roundedBorder)
            
            Picker("Payment type", selection: $paymentType) {
                Text("Credit")
                    .tag(TapOnPhonePaymentType.credit)
                
                Text("Debit")
                    .tag(TapOnPhonePaymentType.debit)
            }
            .pickerStyle(.segmented)
            
            TextField("Installments", value: $installments, format: .number)
                .textFieldStyle(.roundedBorder)
            
            TextField("Metadata", text: $metadata)
                .textFieldStyle(.roundedBorder)
        }
        .disabled(!isInitialized)
    }
    
    var payStatus: some View {
        if isLoadingPayment {
            Text("Loading...")
        } else if paySuccess != nil {
            Text("Success!")
        } else if let payError {
            Text("Error: [\(payError.error.code.rawValue)] \(payError.error.message)")
        } else {
            Text("")
        }
    }
}

#Preview {
    ContentView()
}
