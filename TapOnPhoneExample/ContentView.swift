//
//  ContentView.swift
//  TapOnPhoneExample
//
//  Created by Wellington Hirsch on 11/02/25.
//

import SwiftUI
import TapOnPhoneSDK

struct ContentView: View {
    
    @State private var initializeError: TapOnPhoneError?
    
    // Configuration state
    @State private var isApplyingConfig = false
    @State private var isConfigApplied = false
    
    // Background behavior options
    @State private var autoInitializeInBackground = false
    @State private var autoCreateSessionInBackground = false
    
    // Payment flow state
    @State private var amount: Int = 1
    @State private var paymentType: TapOnPhonePaymentType = .credit
    @State private var installments: Int = 1
    @State private var metadata: String = ""
    
    @State private var isLoadingPayment = false
    @State private var paySuccess: PaymentApprovedResponse?
    @State private var payError: PaymentErrorResponse?
    
    // Sheet navigation for payment flow
    @State private var showPaymentSheet = false
    @State private var paymentStep: PaymentStep = .enterAmount
    
    var body: some View {
        VStack {
            Text("TapOnPhone Example")
                .bold()
            
            // You always can know the SDK version using the TapOnPhone.getVersion() method
            Text("SDK version: \(TapOnPhone.getVersion())")
            
            Spacer()
            
            // 0. Apply Configurations (mandatory, one-time)
            Button {
                guard !isConfigApplied else { return }
                isApplyingConfig = true
                
                // You NEED to call TapOnPhone.setConfig() before calling initialize or pay.
                TapOnPhone.setConfig(configParameters:
                    .init(credentials: .init(
                        marketplace: "",
                        seller: "",
                        accessKey: "")
                    )
                )
                
                // Mark config as applied and disable this button permanently.
                isApplyingConfig = false
                isConfigApplied = true
            } label: {
                Text(isConfigApplied ? "Configurações aplicadas" : "Aplicar configurações")
                    .bold()
            }
            .disabled(isApplyingConfig || isConfigApplied)
            
            // Background behavior options
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $autoInitializeInBackground) {
                    Text("Inicializar em segundo plano ao pagar")
                }
                .onChange(of: autoInitializeInBackground) { newValue in
                    // If init is turned off, also turn off session.
                    if !newValue { autoCreateSessionInBackground = false }
                }
                
                Toggle(isOn: Binding(
                    get: { autoCreateSessionInBackground },
                    set: { newVal in
                        // Allow enabling session only if init is enabled.
                        if autoInitializeInBackground { autoCreateSessionInBackground = newVal }
                        else { autoCreateSessionInBackground = false }
                    }
                )) {
                    Text("Criar sessão em segundo plano ao pagar")
                }
                .disabled(!autoInitializeInBackground)
                
                Text("Dica: se marcar, ao iniciar o fluxo de pagamento nós disparamos a inicialização/sessão antes do pagamento; caso contrário, o SDK inicializa automaticamente durante o pay.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .disabled(!isConfigApplied) // só após aplicar config
            
            
            Spacer()
            
            // Único botão: Pagamento
            Button {
                guard isConfigApplied else { return }
                // Reset flow state
                amount = 0
                paymentType = .credit
                installments = 1
                metadata = ""
                paySuccess = nil
                payError = nil
                paymentStep = .enterAmount
                showPaymentSheet = true
            } label: {
                Text("Pagamento")
                    .bold()
            }
            .disabled(!isConfigApplied)
            
            payStatus
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showPaymentSheet) {
            PaymentFlowView(
                amount: $amount,
                paymentType: $paymentType,
                installments: $installments,
                metadata: $metadata,
                initializeError: $initializeError,
                autoInitializeInBackground: autoInitializeInBackground,
                autoCreateSessionInBackground: autoCreateSessionInBackground,
                paymentStep: $paymentStep,
                isLoadingPayment: $isLoadingPayment,
                paySuccess: $paySuccess,
                payError: $payError,
                onClose: { showPaymentSheet = false }
            )
        }
    }
}

// MARK: - Payment Steps
enum PaymentStep {
    case enterAmount
    case chooseType
    case processing
}

// MARK: - Subviews
extension ContentView {
    
    var payStatus: some View {
        if isLoadingPayment {
            Text("Loading...")
        } else if paySuccess != nil {
            Text("Success!")
        } else if let payError {
            Text("Error: [\(payError.error.code.rawValue)] \(payError.error.message)\n \(payError.error.description ?? "")")
        } else {
            Text("")
        }
    }
}

// MARK: - Payment Flow View
struct PaymentFlowView: View {
    @Binding var amount: Int
    @Binding var paymentType: TapOnPhonePaymentType
    @Binding var installments: Int
    @Binding var metadata: String
    
    @Binding var initializeError: TapOnPhoneError?
    
    var autoInitializeInBackground: Bool
    var autoCreateSessionInBackground: Bool
    
    @Binding var paymentStep: PaymentStep
    @Binding var isLoadingPayment: Bool
    @Binding var paySuccess: PaymentApprovedResponse?
    @Binding var payError: PaymentErrorResponse?
    
    var onClose: () -> Void
    
    // Prevent multiple triggers per presentation
    @State private var didTriggerBackgroundOps = false
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Pagamento")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fechar") { onClose() }
                    }
                }
        }
        .task {
            guard !didTriggerBackgroundOps else { return }
            didTriggerBackgroundOps = true
            
            if autoInitializeInBackground {
                TapOnPhone.initialize(
                    onSuccess: { },
                    onError: { _ in },
                    onEvent: { event in print(event) }
                )
            }
            if autoCreateSessionInBackground {
                TapOnPhone.activateSession(
                    onSuccess: { _ in },
                    onError: { _ in },
                    onEvent: { event in print(event) }
                )
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        switch paymentStep {
        case .enterAmount:
            VStack(spacing: 16) {
                TextField("Valor (centavos)", value: $amount, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    paymentStep = .chooseType
                } label: {
                    Text("Continuar")
                        .bold()
                }
                .disabled(amount <= 0)
            }
            .padding()
        
        case .chooseType:
            VStack(spacing: 16) {
                Picker("Tipo de pagamento", selection: $paymentType) {
                    Text("Crédito").tag(TapOnPhonePaymentType.credit)
                    Text("Débito").tag(TapOnPhonePaymentType.debit)
                }
                .pickerStyle(.segmented)
                
                TextField("Parcelas", value: $installments, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Metadata", text: $metadata)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    paymentStep = .processing
                    startPayment()
                } label: {
                    Text("Pagar")
                        .bold()
                }
            }
            .padding()
        
        case .processing:
            VStack(spacing: 16) {
                ProgressView()
                Text("Processando pagamento...")
            }
            .padding()
            .onChange(of: paySuccess) { _ in
                if paySuccess != nil { onClose() }
            }
            .onChange(of: payError) { _ in
                if payError != nil { onClose() }
            }
        }
    }
    
    
    private func startPayment() {
        isLoadingPayment = true
        TapOnPhone.pay(
            payRequest: PaymentRequest(
                amount: amount,
                paymentType: paymentType,
                installments: installments,
                metadata: metadata
            ),
            onSuccess: { success in
                isLoadingPayment = false
                paySuccess = success
            },
            onError: { error in
                print("error \(error)")
                isLoadingPayment = false
                if error.type == .payment {
                    payError = error.error as? PaymentErrorResponse
                } else {
                    initializeError = error.error as? TapOnPhoneError
                }
            },
            onEvent: { event in
                print(event)
            }
        )
    }
}

#Preview {
    ContentView()
}
