import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { Camera, MapPin, Loader2, ArrowLeft } from 'lucide-react';
import { toast } from 'sonner';
import { PaymentModal } from './PaymentModal';
import { motion } from 'motion/react';

interface PostFormProps {
  type: 'lost' | 'found';
  onCancel: () => void;
  onSuccess: () => void;
}

interface FormData {
  title: string;
  description: string;
  phone: string;
  type: 'lost' | 'found';
}

export const PostForm: React.FC<PostFormProps> = ({ type: initialType, onCancel, onSuccess }) => {
  const [showPayment, setShowPayment] = useState(false);
  const [selectedType, setSelectedType] = useState<'lost' | 'found'>(initialType);
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    defaultValues: { type: initialType }
  });

  const onSubmit = async (data: FormData) => {
    // Override type with state
    const finalData = { ...data, type: selectedType };
    
    if (selectedType === 'lost') {
      setShowPayment(true);
    } else {
      // Direct publish
      await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate API
      toast.success('Publication ajoutée avec succès !');
      onSuccess();
    }
  };

  const handlePaymentSuccess = async () => {
    setShowPayment(false);
    toast.success('Paiement accepté ! Publication ajoutée.');
    onSuccess();
  };

  return (
    <div className="max-w-2xl mx-auto">
      <button 
        onClick={onCancel}
        className="flex items-center gap-2 text-gray-500 hover:text-gray-900 mb-6 transition-colors"
      >
        <ArrowLeft size={20} />
        Retour
      </button>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden"
      >
        <div className="p-8 border-b border-gray-100">
          <h2 className="text-2xl font-bold text-gray-900">
            {selectedType === 'lost' ? 'Signalement Objet Perdu' : 'Signalement Objet Trouvé'}
          </h2>
          <p className="text-gray-500 mt-1">
            Remplissez les détails ci-dessous pour publier votre annonce.
          </p>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-8 space-y-6">
          
          {/* Type Toggle */}
          <div className="grid grid-cols-2 gap-4 p-1 bg-gray-50 rounded-xl">
            <button
              type="button"
              onClick={() => setSelectedType('lost')}
              className={`py-3 rounded-lg font-medium transition-all ${
                selectedType === 'lost' 
                  ? 'bg-white text-red-600 shadow-sm' 
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              Objet Perdu
            </button>
            <button
              type="button"
              onClick={() => setSelectedType('found')}
              className={`py-3 rounded-lg font-medium transition-all ${
                selectedType === 'found' 
                  ? 'bg-white text-green-600 shadow-sm' 
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              Objet Trouvé
            </button>
          </div>

          {/* Title */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700">Titre de l'objet</label>
            <input 
              {...register('title', { required: 'Le titre est requis' })}
              placeholder="Ex: Clés de voiture BMW" 
              className="w-full p-3 bg-gray-50 border border-gray-200 rounded-xl focus:border-violet-500 focus:ring-2 focus:ring-violet-200 outline-none transition-all"
            />
            {errors.title && <span className="text-red-500 text-xs">{errors.title.message}</span>}
          </div>

          {/* Photos */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700">Photos</label>
            <div className="border-2 border-dashed border-gray-200 rounded-xl p-8 flex flex-col items-center justify-center text-gray-400 hover:border-violet-400 hover:bg-violet-50/10 transition-colors cursor-pointer group">
              <div className="w-12 h-12 bg-gray-100 group-hover:bg-violet-100 rounded-full flex items-center justify-center mb-3 transition-colors">
                <Camera size={24} className="text-gray-500 group-hover:text-violet-600" />
              </div>
              <span className="text-sm font-medium">Cliquez pour ajouter des photos</span>
              <span className="text-xs mt-1">JPG, PNG (max 5MB)</span>
            </div>
          </div>

          {/* Description */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700">Description détaillée</label>
            <textarea 
              {...register('description', { required: 'Une description est requise' })}
              rows={4}
              placeholder="Décrivez l'objet, le lieu exact, l'heure..." 
              className="w-full p-3 bg-gray-50 border border-gray-200 rounded-xl focus:border-violet-500 focus:ring-2 focus:ring-violet-200 outline-none transition-all resize-none"
            />
             {errors.description && <span className="text-red-500 text-xs">{errors.description.message}</span>}
          </div>

          {/* Location & Contact */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">Lieu</label>
              <div className="relative">
                <MapPin size={20} className="absolute left-3 top-3.5 text-gray-400" />
                <input 
                  type="text"
                  placeholder="Ville, Quartier..." 
                  className="w-full pl-10 p-3 bg-gray-50 border border-gray-200 rounded-xl focus:border-violet-500 focus:ring-2 focus:ring-violet-200 outline-none transition-all"
                />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">Numéro de téléphone</label>
              <input 
                {...register('phone', { required: 'Numéro requis pour contact' })}
                type="tel"
                placeholder="+212 6..." 
                className="w-full p-3 bg-gray-50 border border-gray-200 rounded-xl focus:border-violet-500 focus:ring-2 focus:ring-violet-200 outline-none transition-all"
              />
              {errors.phone && <span className="text-red-500 text-xs">{errors.phone.message}</span>}
            </div>
          </div>

          {/* Submit Button */}
          <div className="pt-4">
            <button 
              type="submit" 
              disabled={isSubmitting}
              className="w-full py-4 bg-violet-600 hover:bg-violet-700 text-white font-bold rounded-xl shadow-lg shadow-violet-200 transition-all flex items-center justify-center gap-2"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="animate-spin" size={20} />
                  Publication...
                </>
              ) : (
                'Publier l\'annonce'
              )}
            </button>
            <p className="text-center text-xs text-gray-400 mt-4">
              {selectedType === 'lost' 
                ? 'Un paiement de 10 DH sera demandé à l\'étape suivante.' 
                : 'La publication d\'objets trouvés est 100% gratuite.'}
            </p>
          </div>
        </form>
      </motion.div>

      {showPayment && (
        <PaymentModal 
          amount="10 DH" 
          onClose={() => setShowPayment(false)}
          onConfirm={handlePaymentSuccess}
        />
      )}
    </div>
  );
};
