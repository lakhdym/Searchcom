import React, { useState, useEffect } from 'react';
import { X, Send, User } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { toast } from 'sonner';

interface Comment {
  id: string;
  user: string;
  text: string;
  date: string;
  avatar?: string;
}

interface CommentsModalProps {
  isOpen: boolean;
  onClose: () => void;
  postId: string;
  initialCount?: number;
}

const MOCK_COMMENTS: Comment[] = [
  { id: '1', user: 'Amine T.', text: 'J\'espère que vous allez le retrouver !', date: 'Il y a 2h' },
  { id: '2', user: 'Sarah L.', text: 'Je partage sur mes réseaux.', date: 'Il y a 5h' },
  { id: '3', user: 'Karim B.', text: 'Avez-vous demandé à la réception ?', date: 'Il y a 1j' },
];

export const CommentsModal: React.FC<CommentsModalProps> = ({ isOpen, onClose, postId, initialCount = 0 }) => {
  const [comments, setComments] = useState<Comment[]>([]);
  const [newComment, setNewComment] = useState('');

  useEffect(() => {
    if (isOpen) {
      // Simulate fetching comments
      // If initialCount is small, show fewer, if large show more or just random subset
      setComments(MOCK_COMMENTS.slice(0, Math.max(1, initialCount))); 
    }
  }, [isOpen, initialCount]);

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newComment.trim()) return;

    const comment: Comment = {
      id: Date.now().toString(),
      user: 'Moi',
      text: newComment,
      date: 'À l\'instant',
    };

    setComments([...comments, comment]);
    setNewComment('');
    toast.success('Commentaire ajouté');
  };

  if (!isOpen) return null;

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
        className="relative bg-white rounded-3xl shadow-2xl w-full max-w-md overflow-hidden flex flex-col max-h-[80vh]"
      >
        {/* Header */}
        <div className="p-4 border-b border-gray-100 flex items-center justify-between bg-white z-10">
          <h3 className="text-lg font-bold text-gray-900">Commentaires ({comments.length})</h3>
          <button onClick={onClose} className="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors">
            <X size={20} />
          </button>
        </div>

        {/* Comments List */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {comments.length === 0 ? (
            <div className="text-center py-10 text-gray-500 text-sm">
              Soyez le premier à commenter
            </div>
          ) : (
            comments.map((comment) => (
              <div key={comment.id} className="flex gap-3">
                <div className="w-8 h-8 rounded-full bg-violet-100 flex items-center justify-center text-violet-600 flex-shrink-0">
                  <User size={14} />
                </div>
                <div className="bg-gray-50 p-3 rounded-2xl rounded-tl-none text-sm w-full">
                  <div className="flex justify-between items-baseline mb-1">
                    <span className="font-bold text-gray-900">{comment.user}</span>
                    <span className="text-xs text-gray-400">{comment.date}</span>
                  </div>
                  <p className="text-gray-700">{comment.text}</p>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Input Area */}
        <form onSubmit={handleSend} className="p-4 border-t border-gray-100 bg-white">
          <div className="relative flex items-center gap-2">
            <input
              type="text"
              value={newComment}
              onChange={(e) => setNewComment(e.target.value)}
              placeholder="Ajouter un commentaire..."
              className="w-full bg-gray-50 border-none rounded-full py-3 pl-4 pr-12 text-sm focus:ring-2 focus:ring-violet-200 outline-none transition-shadow"
            />
            <button 
              type="submit"
              disabled={!newComment.trim()}
              className="absolute right-1 p-2 bg-violet-600 text-white rounded-full hover:bg-violet-700 disabled:opacity-50 disabled:hover:bg-violet-600 transition-colors"
            >
              <Send size={16} />
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};
