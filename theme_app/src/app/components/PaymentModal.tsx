import React, { useState } from 'react';
import { X, CreditCard, Wallet, Lock } from 'lucide-react';
import { motion } from 'motion/react';

interface PaymentModalProps {
  amount: string;
  onClose: () => void;
  onConfirm: () => void;
}

export const PaymentModal: React.FC<PaymentModalProps> = ({ amount, onClose, onConfirm }) => {
  const [selectedMethod, setSelectedMethod] = useState<'card' | 'paypal'>('card');
  const [isProcessing, setIsProcessing] = useState(false);

  const handlePay = () => {
    setIsProcessing(true);
    // Simulate payment processing
    setTimeout(() => {
      setIsProcessing(false);
      onConfirm();
    }, 2000);
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
      />
      
      <motion.div 
        initial={{ scale: 0.95, opacity: 0, y: 20 }}
        animate={{ scale: 1, opacity: 1, y: 0 }}
        exit={{ scale: 0.95, opacity: 0, y: 20 }}
        className="relative bg-white rounded-3xl shadow-2xl w-full max-w-md overflow-hidden"
      >
        <div className="p-6 pb-0">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-xl font-bold text-gray-900">Finaliser la publication</h3>
            <button onClick={onClose} className="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors">
              <X size={20} />
            </button>
          </div>
          
          <div className="bg-violet-50 text-violet-800 p-4 rounded-xl text-sm mb-6 border border-violet-100">
            Pour publier une annonce <span className="font-bold">"Objet perdu"</span>, une participation de <span className="font-bold text-lg mx-1">{amount}</span> est requise.
          </div>

          <div className="space-y-3 mb-8">
            <label className="text-sm font-medium text-gray-700 block mb-2">Moyen de paiement</label>
            
            <button 
              onClick={() => setSelectedMethod('card')}
              className={`w-full flex items-center p-4 rounded-xl border-2 transition-all ${
                selectedMethod === 'card' 
                  ? 'border-violet-600 bg-violet-50/50' 
                  : 'border-gray-100 hover:border-violet-200'
              }`}
            >
              <div className={`w-5 h-5 rounded-full border flex items-center justify-center mr-4 ${selectedMethod === 'card' ? 'border-violet-600' : 'border-gray-300'}`}>
                {selectedMethod === 'card' && <div className="w-2.5 h-2.5 bg-violet-600 rounded-full" />}
              </div>
              <div className="flex items-center gap-3 flex-1">
                <div className="bg-blue-100 text-blue-600 p-2 rounded-lg">
                  <CreditCard size={20} />
                </div>
                <span className="font-medium text-gray-900">Carte Bancaire</span>
              </div>
            </button>

            <button 
              onClick={() => setSelectedMethod('paypal')}
              className={`w-full flex items-center p-4 rounded-xl border-2 transition-all ${
                selectedMethod === 'paypal' 
                  ? 'border-violet-600 bg-violet-50/50' 
                  : 'border-gray-100 hover:border-violet-200'
              }`}
            >
              <div className={`w-5 h-5 rounded-full border flex items-center justify-center mr-4 ${selectedMethod === 'paypal' ? 'border-violet-600' : 'border-gray-300'}`}>
                {selectedMethod === 'paypal' && <div className="w-2.5 h-2.5 bg-violet-600 rounded-full" />}
              </div>
              <div className="flex items-center gap-3 flex-1">
                <div className="bg-[#003087]/10 text-[#003087] p-2 rounded-lg">
                  <Wallet size={20} /> {/* PayPal generic icon proxy */}
                </div>
                <span className="font-medium text-gray-900">PayPal</span>
              </div>
            </button>
          </div>
        </div>

        <div className="p-6 border-t border-gray-100 bg-gray-50 flex items-center justify-between">
          <div className="flex items-center gap-2 text-xs text-gray-500">
            <Lock size={12} />
            Paiement sécurisé
          </div>
          <div className="flex gap-3">
            <button 
              onClick={onClose}
              className="px-4 py-2 text-gray-600 font-medium hover:bg-gray-200 rounded-lg transition-colors"
            >
              Annuler
            </button>
            <button 
              onClick={handlePay}
              disabled={isProcessing}
              className="px-6 py-2 bg-violet-600 hover:bg-violet-700 text-white font-medium rounded-lg shadow-lg shadow-violet-200 transition-all flex items-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
            >
              {isProcessing ? 'Traitement...' : `Payer ${amount}`}
            </button>
          </div>
        </div>
      </motion.div>
    </div>
  );
};
